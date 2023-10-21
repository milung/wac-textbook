
FROM milung/book-builder:latest

RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/CET /etc/localtime
RUN mkdir -p /root/.config/powershell \
    && echo "function run {" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "  if (Test-Path -Path "${PWD}/scripts/run.ps1") {" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "      invoke-expression "${PWD}/scripts/run.ps1 $args"" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "  }" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "  else {" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "      if(Test-Path -Path "${PWD}/package.json") {" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "      npm run $args" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "      }" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "      else {" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "          echo "No run.ps1 or package.json found in the current folder"" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "      } " >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "  }" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "}" >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1



