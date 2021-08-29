# _makeDC
scripts to automate domain controller installations

## Infos
### _makeDC1.ps1
* Script for first domain controller.
* This script needs administrative permissions to run.
* This script needs no further modules to be installed.
* Currently it is only possible to run the script on the machine that should become a domain controller.

### _makeDCX.ps1
* Script for additional domain controller.
* This script needs administrative permissions to run.
* This script need no further modules to be installed.
* Currently it is only possible to run the script on the machine that should become a domain controller.

## Options
### primary domain controller
```powershell
PS> Get-Content "<configfile>"
<config>
...
</config>
PS> .\_makeDC1.ps1 -configfile "<configfile>"
```
Installs and configures first DC in domain CONTOSO
### additional domain controller
```powershell
PS> Get-Content "<configfile>"
<config>
...
</config>
PS> .\_makeDCX.ps1 -configfile "<configfile>"
```
Installs and configures additional DC in domain CONTOSO

## Further Infos/Examples
