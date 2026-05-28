# Poll the VM every 2 minutes for build progress. Exits when `docker compose
# up` has stopped (either build finished or build failed). Emits a "DONE"
# marker line that the agent watcher matches on.

$host_ = "ubuntu@35.223.220.115"

# Single-line remote command (no heredoc - keeps PS escaping simple)
$remoteCmd = "running=`$(pgrep -f 'docker compose.*up -d' | head -1); if [ -n `"`$running`" ]; then echo STATUS=RUNNING; else echo STATUS=STOPPED; fi; tail -1 /var/log/app-build.log 2>/dev/null | sed 's/^/LAST: /'; free -m | awk '/^Mem:/ {print `"MEM: `"`$3`"/`"`$2`"MB used `"`$7`"MB avail`"}'; docker ps --format 'PS: {{.Names}} {{.Status}}'"

while ($true) {
    $now = Get-Date -Format "HH:mm:ss"
    $out = ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=15 $host_ "sudo bash -c `"$remoteCmd`"" 2>&1
    Write-Host "----- [$now] -----"
    $out | ForEach-Object { Write-Host $_ }

    if ($out -match 'STATUS=STOPPED') {
        Write-Host "----- [$now] BUILD ENDED -----"
        Write-Host "Last 50 lines of build log:"
        ssh -o StrictHostKeyChecking=no -o BatchMode=yes $host_ "sudo tail -50 /var/log/app-build.log; echo '---ALL CONTAINERS---'; sudo docker ps -a" 2>&1 | ForEach-Object { Write-Host $_ }
        Write-Host "WATCHER_DONE"
        break
    }
    Start-Sleep -Seconds 120
}
