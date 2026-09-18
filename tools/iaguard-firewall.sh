#!/usr/bin/env bash
# IAGuard firewall helper — helper de UNA función, instalado UNA vez por el usuario.
#
#   Uso:  iaguard-firewall status | list | deny <ip> | allow <ip>
#
# - Linux: ufw   (reglas propias etiquetadas "IAGuard BLOCK <ip>": entrante con
#                `ufw deny from` y saliente con `ufw deny out to`; jamás toca reglas ajenas)
# - macOS: pfctl (anchor propio "com.iaguard" con tabla <blocked>; la dirección de
#                bloqueo la definen las reglas del anchor: configúralo para
#                entrante Y saliente, p. ej. `block in from <blocked>` +
#                `block out to <blocked>`)
# - Windows: NO usa este helper (la app usa New-NetFirewallRule con -DisplayName
#            propio, Inbound + Outbound)
#
# Instalación (una vez, sin contraseña en runtime):
#   sudo install -m 0755 tools/iaguard-firewall.sh /usr/local/sbin/iaguard-firewall
#   # y en /etc/sudoers.d/iaguard (SOLO este helper, NOPASSWD — nunca un sudo genérico):
#   %wheel ALL=(root) NOPASSWD: /usr/local/sbin/iaguard-firewall status, \
#       /usr/local/sbin/iaguard-firewall list, \
#       /usr/local/sbin/iaguard-firewall deny *, \
#       /usr/local/sbin/iaguard-firewall allow *
#
# Nunca pide contraseña en runtime: si no está autorizado, `sudo -n` falla al
# instante y la app degrada con la guía (misma filosofía que la captura).
set -u

ACTION="${1:-}"
IP="${2:-}"

# Auto-elevación NO interactiva (falla sin contraseña si no está en sudoers).
if [ "$(id -u)" -ne 0 ]; then
	exec sudo -n /usr/local/sbin/iaguard-firewall "$@"
fi

case "$ACTION" in
	status)
		if command -v pfctl >/dev/null 2>&1; then
			echo "ok"; exit 0
		fi
		if command -v ufw >/dev/null 2>&1 && ufw status >/dev/null 2>&1; then
			echo "ok"; exit 0
		fi
		echo "no firewall helper"; exit 1
		;;
	deny)
		if [ -z "$IP" ]; then exit 2; fi
		if command -v pfctl >/dev/null 2>&1; then
			if pfctl -a com.iaguard -t blocked -T add "$IP" >/dev/null 2>&1; then
				echo "DENY $IP"; exit 0
			fi
			exit 1
		fi
		if command -v ufw >/dev/null 2>&1; then
			# Entrante (atención del remoto hacia nosotros) y saliente (nosotros
			# hacia el remoto: p. ej. malware que llama a su C2).
			if ufw deny from "$IP" comment "IAGuard BLOCK $IP" >/dev/null 2>&1 \
				&& ufw deny out to "$IP" comment "IAGuard BLOCK OUT $IP" >/dev/null 2>&1; then
				echo "DENY $IP"; exit 0
			fi
			exit 1
		fi
		exit 1
		;;
	allow)
		if [ -z "$IP" ]; then exit 2; fi
		if command -v pfctl >/dev/null 2>&1; then
			if pfctl -a com.iaguard -t blocked -T delete "$IP" >/dev/null 2>&1; then
				echo "ALLOW $IP"; exit 0
			fi
			exit 1
		fi
		if command -v ufw >/dev/null 2>&1; then
			# Tolerante: borra lo que exista (solo entrante, solo saliente o ambas).
			ufw delete deny from "$IP" >/dev/null 2>&1
			ufw delete deny out to "$IP" >/dev/null 2>&1
			echo "ALLOW $IP"; exit 0
		fi
		exit 1
		;;
	list)
		if command -v pfctl >/dev/null 2>&1; then
			pfctl -a com.iaguard -t blocked -T show 2>/dev/null | tail -n +2 | tr -d ' '
		elif command -v ufw >/dev/null 2>&1; then
			# `ufw status numbered` muestra el comentario de cada regla;
			# extraemos solo las nuestras (IAGuard BLOCK <ip> o IAGuard BLOCK OUT <ip>),
			# una vez por IP (dedupe por si la IP tiene regla entrante y saliente).
			ufw status numbered 2>/dev/null | grep -E "IAGuard BLOCK" \
				| sed -E 's/.*IAGuard BLOCK( OUT)?[ =]+([0-9a-fA-F:.]+).*/\2/' | sort -u
		fi
		exit 0
		;;
	*)
		echo "uso: $0 status|list|deny <ip>|allow <ip>" >&2
		exit 2
		;;
esac