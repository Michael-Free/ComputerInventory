# ComputerInventory
This is a quick and dirty Powershell framework to perform a basic inventory of systems by polling the domain controller of all joined computers to that domain and collecting any relevant information about those computers/devices.  This involves gathering serial numbers, system specs, computer types, keyboards, mice, monitors, memory, storage capacity, storage type (HDD/SSD), hostnames, likely system formfactor (laptop/desktop/etc) and other relevant system information.

Once the domain is polled for relevant system information including physical verification will need to be performed of systems detected, and systems that may not be connected to the domain controller, or unable to get relevant information in the first place. **This is not meant as a replacement for proper inventory/asset-management system - but a stopgap to figure out what may or may not exist in the first place**

## Table of Contents
## Scenario
This framework is used in a predominately Windows Server/Window Desktop environment. It presumes that WinRM is installed on most computers in the domain. Since no inventory of systems has taken place before,  it uses the domain controller as a source of truth for what computers are connected to the network. 

If systems are re-purposed and given diffrent hostnames - it can be assumed there is bloat in the domain controller and therefore bloating group policies and that will need to be addressed outside of this framework.  This could be considered a security risk but also someting that can degrade the performance of your Window Server environment and other connected systems.

To reitterate from the project description - this means we are working in an environment where no inventory controls have ever taken place before.

## Requirements
https://www.microsoft.com/en-ca/download/details.aspx?id=45520

## Usage
### InvetoryDomain
### InventoryLocal

## Logic
It will systematically go through each joined computer and attempt to connect to them and determine if they are offline or attempt to connect to them by using PsExec by Windows Sysinternals and 

## Credits
