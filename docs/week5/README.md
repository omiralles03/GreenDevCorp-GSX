# Setmana 5: Storage, Backups & Xarxa NFS

Aquest document detalla l'arquitectura implementada per a la Setmana 5, el raonament darrere de les decisions preses seguint els principis d'**Infraestructura com a Codi (IaC)**, i els passos pendents per finalitzar la integració.

## 1. Arquitectura i Decisions de Disseny (El perquè de les coses)

Per resoldre els reptes d'aquesta setmana, hem dividit el treball en dues grans àrees: **Emmagatzematge Físic** (Hardware/OS) i **Lògica de Backups i Xarxa** (Serveis).

Hem establert un "contracte" entre les dues parts: **tota la lògica de programació apuntarà a la ruta `/mnt/backups`**. 

### Per què hem descartat la carpeta compartida de VirtualBox (`vboxsf`)?
Inicialment havíem pensat simular el NAS guardant els backups directament a una carpeta compartida amb el Windows (Host). No obstant això, revisant la rúbrica oficial (Punts 1 i 5), el professor demana explícitament:
* *"New disk added and partitioned"*
* *"Filesystem created and mounted"*
* *"Persistent mount configuration in /etc/fstab"*

Si utilitzem `vboxsf`, ens saltem el particionament (`fdisk`) i el formateig (`mkfs.ext4`), la qual cosa ens faria perdre punts. Per tant, **hem de crear un segon disc dur virtual (.vdi) real**.

### Automatització i Manteniment
1. **Backups (`service_backups.sh`)**: El script empaqueta en `.tar.gz` els directoris vitals (`/etc`, `/opt`, `/home`, `/root`, `/usr/local`). S'executa automàticament cada dia a les 05:00 AM mitjançant un *timer* de `systemd`.
2. **Logrotate**: S'ha implementat una regla a `/etc/logrotate.d/gsx_backups` per evitar que el fitxer `/var/log/gsx_backups.log` creixi infinitament. Rota setmanalment, comprimeix els antics i guarda l'historial d'un mes (4 setmanes).
3. **NFS Server (`setup_nfs_server.sh`)**: Per complir el requeriment de *Networked Storage*, s'ha instal·lat `nfs-kernel-server` que exporta la carpeta `/mnt/backups` a la xarxa local de la VM (`10.0.2.0/24`), permetent que altres màquines llegeixin els backups.

### Testeigs Automatitzats
Hem creat dos scripts a `/scripts/tests/` per validar el sistema sense intervenció manual:
* **`test_backups.sh`**: Busca l'últim `.tar.gz`, comprova que no estigui corrupte amb `tar -tzf`, l'extreu en una carpeta temporal (`/tmp/restore_test`) i verifica que tots els directoris crítics existeixen.
* **`test_nfs_client.sh`**: S'executa al Host, clona la nostra VM en un segon usant *Linked Clones*, l'arrenca, li instal·la el client NFS per "la porta del darrere", munta la carpeta per xarxa, llista els backups i s'apaga.

---

## 2. Tasques Pendents (Instruccions per al company)

Per tancar la Setmana 5, falta tota la part de **Hardware i Emmagatzematge** (Punts 1 i 2 de la rúbrica). 

**Passos a seguir (idealment en una branca `feat/storage-setup`):**

1. **Modificar `setup_vbox.sh`**: 
   Afegeix les instruccions de VirtualBox (`VBoxManage createmedium disk ...` i `storageattach`) per crear i connectar un segon disc `.vdi` (ex. de 5GB o 10GB) a la màquina `debian-gsx`.
2. **Crear `setup_storage.sh`**:
   Crea un nou script d'automatització a `/scripts/services/` que s'executi durant el bootstrap. Aquest script ha de:
   * Detectar el nou disc (normalment `/dev/sdb`).
   * Particionar-lo (pots usar `fdisk` o `parted` automàticament).
   * Formatejar-lo (`mkfs.ext4 /dev/sdb1`).
   * Crear la carpeta de destí (`mkdir -p /mnt/backups`).
   * Afegir l'entrada a `/etc/fstab` i fer un `mount -a`.
3. **Afegir-lo al Bootstrap**:
   Recorda cridar el teu nou script dins de `scripts/bootstrap/setup_services.sh` (hauria d'anar ABANS que s'executin els scripts de backup o NFS, perquè les carpetes estiguin llistes).
4. **Documentació del Backup**:
   Redactar al README la justificació de la política de backups (Regla 3-2-1, RTO, RPO i freqüència).

---

## 3. Com provar que tot el sistema integrat funciona

Un cop fusionades les branques de Lògica i Storage, pots verificar que el sistema complet és funcional seguint aquests 5 passos des del Host (Windows):

1. **Desplegar canvis**:
   ```bash
   ./scripts/bootstrap/run_setup_system.sh

2. **Forçar el backup**:
    ```bash
   sudo systemctl start admin_backup.service
   ls -lh /mnt/backups
3. **Integritat al servidor (restore)**
    ```bash
    sudo bash /opt/admin/scripts/tests/test_backups.sh
4. **Test client NFS**
    ```bash
    ./scripts/tests/test_nfs_client.sh
***