# cyberrange-vm-deployment-tool
This tool standardizes VM deployment, enforces a one-VM quota, validates resource group access, and automatically configures networking for Windows or Linux virtual machines.





1. Right click on blank part of desktop and select "New" then "Shortcut"
 <img width="382" height="251" alt="image" src="https://github.com/user-attachments/assets/b7c33ffb-b8a8-4073-87a7-1ce6a2139909" />

2. Right click > "Run with PowerShell"
<img width="324" height="284" alt="image" src="https://github.com/user-attachments/assets/fc5ec1ef-9461-46a2-a749-763e3f68a59b" />

3. In the box put:
powershell.exe -NoExit -ExecutionPolicy Bypass -File "C:\Users\labadmin\Desktop\VMcreator-v2.ps1" />
NOTE: Change the location to where you have the script saved
- Click Next 
- Name it whatever you like, I Chose VMcreator
- Click Finish

4. Launch the new icon we created. If this is your first time running it and you don't have Azure CLI installed, then click on the link provided to download and isntall it.
<img width="578" height="157" alt="image" src="https://github.com/user-attachments/assets/d111c3d2-ec9c-4edd-ac47-8970b11d28e7" />

5. Check your downloads folder for the installation file. Run it.
<img width="563" height="224" alt="image" src="https://github.com/user-attachments/assets/d1e45a6b-9f35-4f9a-a734-308675de700c" />

6. Go through installation, when it's done there won't be any sort of confirmation by the way.

7. Open a new Powershell screen, now type: az login
   - When the Microsoft login screen apears, click "Work or school account"
   - log in with your xxxxxx@lognpacific.com account
   - Click "No, This app only"
<img width="557" height="322" alt="image" src="https://github.com/user-attachments/assets/b04059c8-7844-4d7d-a54b-dbbd70b9ab54" />


<img width="431" height="388" alt="image" src="https://github.com/user-attachments/assets/1bcf4fad-8bbc-43f2-a41f-21a97c5d77bb" />

















