# 🚀 CyberRange VM Deployment Tool

This tool standardizes VM deployment, enforces quotas, and automates networking for Azure virtual machines.

---

### ✨ Key Features

* **⚡ Smart Config:** Automatically saves your Resource Group name after the first run.
* **🧹 Quota Cleanup:** Identifies existing VMs and offers to wipe them (along with orphaned disks and NICs).
* **🔒 Secure Setup:** Dynamically calculates ingress ports (3389 for RDP or 22 for SSH).
* **🛰️ Smart-Wait:** Probes VM ports every 10 seconds and only offers to connect when the OS is fully "listening."

---
<br>  
This tool can be used to make it easier to delete old resources and automate the deployment of a new Virtual machine in the Cyber Range.
After the initial setup which should take less than 5 minutes, you'll be left with an easy to use 1 click button on your desktop. When you 
launch this, you'll be asked what OS you'd like to install, username/password. If you already have an active VM, it'll let you know and confirm if you'd like to delete it.
Once that's done, it'll create the VM and once done, let you know with the total build time, Public IP, VM name, and username. Then it'll ask if you'd like to RDP or SSH into the VM and launch it for you, if you wish.
<br>  


<br>  

## 📖 Setup Guide

### 1. Create the Desktop Shortcut
Right-click on your desktop and select **New** > **Shortcut**.

<img width="382" height="251" alt="image" src="https://github.com/user-attachments/assets/b7c33ffb-b8a8-4073-87a7-1ce6a2139909" />

### 2. Configure the Path
In the location box, paste the following command:

`powershell.exe -NoExit -ExecutionPolicy Bypass -File "C:\Users\labadmin\Desktop\VMcreator-v2.ps1"`  
NOTE: Change the location to where you have the script saved
* **Name it:** `VMCreator`  
<img width="324" height="284" alt="image" src="https://github.com/user-attachments/assets/fc5ec1ef-9461-46a2-a749-763e3f68a59b" /><br>   
* **Finish!**

---

### 3. Install Azure CLI

You need Azure CLI installed for the tool to communicate with Azure. It'll detect if its installed. If it is go to step 4, if not click on the link provided on the script
to download it and install it.


<img width="578" height="157" alt="image" src="https://github.com/user-attachments/assets/d111c3d2-ec9c-4edd-ac47-8970b11d28e7" />

Check your **Downloads** folder for the installation file and run it.

<img width="563" height="224" alt="image" src="https://github.com/user-attachments/assets/d1e45a6b-9f35-4f9a-a734-308675de700c" />

---

### 4. Azure Authentication
Open a new Powershell window and type:  
'az login'  
After it loads for a minute:  




* Click **"Work or school account"**.
* Log in with your **xxxxxx@lognpacific.com** account.


<img width="557" height="322" alt="image" src="https://github.com/user-attachments/assets/b04059c8-7844-4d7d-a54b-dbbd70b9ab54" /><br>
* Select **"No, This app only"**.
<img width="431" height="388" alt="image" src="https://github.com/user-attachments/assets/1bcf4fad-8bbc-43f2-a41f-21a97c5d77bb" />

On the next terminal screen, hit **Enter**.

<img width="590" height="322" alt="image" src="https://github.com/user-attachments/assets/57969b36-78de-40ed-94e4-39208d1fcf39" /><br>
Now close this window

---

### 5. Running the Tool
Now we can launch the **VMCreator** shortcut.

On the first run, enter your **Resource Group Name**. It will be remembered for all future deployments.  
You can just copy/paste this from Azure portal.
Then you'll be asked which OS to install, username/password and VM name to use.


<img width="761" height="672" alt="image" src="https://github.com/user-attachments/assets/ece5516d-7571-412a-a26d-370a7bfb6355" />

### 6. Success!
Once complete, you'll receive a confirmation with the Public IP and the option to launch RDP or SSH directly.

<img width="433" height="326" alt="image" src="https://github.com/user-attachments/assets/b206c299-cbee-4d5d-a473-4dc973635be7" />











