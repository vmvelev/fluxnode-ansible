## Description

This is a playbook that will install a Flux node on a target machine with UPnP (for multinode hosting purposes).

## How to use

#### Installing Ansible on your controlling server (not the FLUX node).

Execute the following commands one by one:

`sudo apt update`

`sudo apt upgrade`

`sudo apt install python3-pip`

`pip3 --version` and make sure pip3 is now available

`sudo apt install software-properties-common`

`sudo add-apt-repository --yes --update ppa:ansible/ansible`

`sudo apt install ansible`

#### FLUX node preparation:

1. From the ansible machine SSH into the FLUX node and accept the key.
2. If you were able to SSH, type in `logout` which will bring you back to the ansible machine.

#### Running ansible to install FluxOS

1. Download the playbook file (flux.yml) with this command `curl https://raw.githubusercontent.com/vmvelev/fluxnode-ansible/main/flux.yml --output flux.yml`
2. Run the playbook with this command `ansible-playbook ./flux.yml --user flux_node_username --ask-pass -i flux_node_ip,`
3. **Important for point 2 - make sure that the comma (,) at the end is present. It is really important!**
4. Follow the prompts to enter your info.
5. Enjoy!

If you need any help, please reach out to the [#community-support](https://discord.com/channels/404415190835134464/955162276019712010) channel on Discord.

You can also reach me directly - Choco#6778

Feel free to buy me a coffee - t1SuNszsv1bVzyfeHZcKbhKjuX1fuq64Srn
