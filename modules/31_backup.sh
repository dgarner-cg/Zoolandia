#!/bin/bash
################################################################################
# Zoolandia v5.10 - Backup Module
#
# Description: Backup menu for creating Docker folder backups
################################################################################

# Backup Docker folder
show_backup_menu() {
    local backup_dest="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    local display_docker_dir=$(display_path "$DOCKER_DIR")
    local display_backup_dest=$(display_path "$backup_dest")
    if dialog --yesno "Backup Docker folder?\n\nSource: $display_docker_dir\nDestination: $display_backup_dest\n\nThis may take several minutes." 12 70; then
        dialog --infobox "Creating backup...\n\nThis may take a while..." 6 50

        mkdir -p "$BACKUP_DIR"

        if tar -czf "$backup_dest" -C "$(dirname "$DOCKER_DIR")" "$(basename "$DOCKER_DIR")" 2>&1 | tee /tmp/backup.log; then
            local size=$(du -h "$backup_dest" | cut -f1)
            local display_backup_dest=$(display_path "$backup_dest")
            dialog --msgbox "Backup completed successfully!\n\nLocation: $display_backup_dest\nSize: $size" 10 70
        else
            dialog --msgbox "Backup failed!\n\nCheck logs: /tmp/backup.log" 10 50
        fi
    fi
}
