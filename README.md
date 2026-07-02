<img src="https://capsule-render.vercel.app/api?type=waving&height=150&color=timeAuto" alt="Header" style="max-width:100%;" />

<h1 align="center">🏗️ Enterprise High-Availability Infrastructure</h1>
<h3 align="center">Final Project · Internet Services Administration · UNAM FI · 2026-2</h3>

<p align="center">
  <img src="https://img.shields.io/badge/CentOS_Stream_10-262577?style=for-the-badge&logo=centos&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/OpenLDAP-003865?style=for-the-badge&logo=openldap&logoColor=white" />
  <img src="https://img.shields.io/badge/Nextcloud-0082C9?style=for-the-badge&logo=nextcloud&logoColor=white" />
  <img src="https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white" />
  <img src="https://img.shields.io/badge/HAProxy-0033A0?style=for-the-badge&logoColor=white" />
</p>

---

## 📋 Description

Full-stack implementation of an enterprise-grade network architecture for an **architecture firm**, designed as a sovereign, low-cost alternative to commercial platforms. The system guarantees **high availability**, **centralized identity management**, and **secure remote access** for directors, residents, and contractors in the field.

> *Team 7 — Los Soles de México*
> Hernández Ruiz Leny Javier · Silverio Martínez Andrés
> Professor: Ángel Brito Segura

---

## 🏛️ System Architecture

The cluster runs on two VirtualBox VMs with CentOS Stream 10, connected over an isolated private network (`192.168.12.0/24`):

<div align="center">

| Node | IP | Primary Role | Services |
|------|----|--------------|----------|
| **Master** | `192.168.12.200` | Load Balancer & VPN | HAProxy · Keepalived · WireGuard (wg-easy) |
| **Slave** | `192.168.12.201` | Internal Services | Nginx Intranet · OpenLDAP · Nextcloud · PostgreSQL |
| **VIP** | `192.168.12.250` | Floating Virtual IP | Single entry point (Keepalived VRRP) |

</div>

---

## 🚀 Implemented Services

### ⚖️ High Availability — Keepalived + HAProxy
- **Keepalived** manages a floating Virtual IP (VIP `192.168.12.250`) via the VRRP protocol
- If the Master node goes down, the Slave inherits the VIP in **under 2 seconds**
- **HAProxy** distributes incoming HTTP traffic using a round-robin algorithm across internal nodes

### 🌐 Corporate Intranet — Nginx
- Internal web portal for construction progress schedules, accessible via the VIP
- Access restricted through basic HTTP authentication (`htpasswd`)
- Single access point for management staff

### 📁 Active Directory — OpenLDAP (Docker)
- Deployed as a Docker container (`osixia/openldap:1.5.0`) for maximum portability
- Domain: `arquitectura.local`
- Three organizational units: `contratistas`, `directores`, `residentes`
- Integrated with Nextcloud via the **LDAP user and group backend** plugin

### ☁️ Private Cloud — Nextcloud + PostgreSQL (Docker)
- Collaborative storage for blueprints, 3D models, and construction regulations
- **PostgreSQL 15** database in a dedicated container (isolated `red_nextcloud` network)
- Users and groups automatically synced from OpenLDAP
- Accessible via load balancer at `http://192.168.12.250:8080`

### 🔐 Secure VPN — WireGuard (wg-easy)
- Encrypted UDP tunnel on port `51820` for remote access from the Internet
- Web-based admin UI (wg-easy) on port `51821`
- Port Forwarding configured on the ISP router for real external access

---

## 📁 Repository Structure

```
📦 proyecto-final-lossolesdemexico
├── 📂 scripts/
│   ├── keepalivedyhaproxy.sh     # Master setup: Keepalived (MASTER) + HAProxy
│   ├── keepalivedslave.sh        # Slave setup: Keepalived (BACKUP)
│   ├── nginx.sh                  # Corporate intranet with authentication
│   ├── openldap.sh               # OpenLDAP deployment in Docker
│   ├── nextcloud.sh              # Nextcloud + PostgreSQL deployment in Docker
│   └── wireguard.sh              # WireGuard VPN with wg-easy interface
└── 📂 ldif/
    ├── base.ldif                 # Directory base structure (DIT)
    ├── db.ldif                   # Suffix and RootDN configuration
    ├── empleados_final.ldif      # Corporate user entries
    ├── grupos.ldif               # Group definitions (Directores, Residentes)
    └── nuevo_arquitecto.ldif     # New user entry template
```

---

## ⚙️ Quick Deployment

### Prerequisites
- Two VMs running **CentOS Stream 10** on VirtualBox
- Adapter 1: Host-Only (`192.168.12.0/24`) · Adapter 2: NAT or Bridge
- Docker installed on both nodes

### 1. Master Node
```bash
# Keepalived (MASTER) + HAProxy
chmod +x scripts/keepalivedyhaproxy.sh
sudo ./scripts/keepalivedyhaproxy.sh

# WireGuard VPN
chmod +x scripts/wireguard.sh
sudo ./scripts/wireguard.sh
```

### 2. Slave Node
```bash
# Keepalived (BACKUP)
chmod +x scripts/keepalivedslave.sh
sudo ./scripts/keepalivedslave.sh

# Nginx Intranet
chmod +x scripts/nginx.sh
sudo ./scripts/nginx.sh

# OpenLDAP in Docker
chmod +x scripts/openldap.sh
sudo ./scripts/openldap.sh

# Nextcloud + PostgreSQL in Docker
chmod +x scripts/nextcloud.sh
sudo ./scripts/nextcloud.sh
```

### 3. Load the LDAP Directory
```bash
# Copy .ldif files into the container
sudo docker cp ldif/base.ldif servidor_ldap:/base.ldif
sudo docker cp ldif/empleados_final.ldif servidor_ldap:/empleados_final.ldif
sudo docker cp ldif/grupos.ldif servidor_ldap:/grupos.ldif

# Inject into OpenLDAP
sudo docker exec servidor_ldap ldapadd -x -D "cn=admin,dc=arquitectura,dc=local" -w admin123 -f /base.ldif
sudo docker exec servidor_ldap ldapadd -x -D "cn=admin,dc=arquitectura,dc=local" -w admin123 -f /empleados_final.ldif
sudo docker exec servidor_ldap ldapadd -x -D "cn=admin,dc=arquitectura,dc=local" -w admin123 -f /grupos.ldif
```

---

## 📊 Cost Analysis (Production)

<div align="center">

| Scenario | Description | Annual Cost (USD) |
|----------|-------------|-------------------|
| ☁️ Commercial platforms | Per-user licenses (~$72/year × 50 employees) | $3,600 |
| 🐧 **This architecture** | IaaS infrastructure + SysAdmin (5h/month) | **$687** |
| 💰 **Direct savings** | Cost reduction by using open-source software | **$2,913** |

</div>

---

## 👥 Team

<div align="center">

| Member | GitHub |
|--------|--------|
| Andrés Silverio Martínez | [@Kylos02](https://github.com/Kylos02) |
| Leny Javier Hernández Ruiz | — |

</div>

---

## 📚 References

- [Docker Documentation](https://docs.docker.com/)
- [WireGuard](https://www.wireguard.com/)
- [HAProxy Documentation](https://docs.haproxy.org/)
- [Keepalived Documentation](https://keepalived.org/doc/)
- [Nextcloud Documentation](https://docs.nextcloud.com/)
- [OpenLDAP Administrator's Guide](https://www.openldap.org/doc/admin26/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

<img src="https://capsule-render.vercel.app/api?type=waving&height=100&section=footer&color=timeAuto" alt="Footer" style="max-width:100%;" />
