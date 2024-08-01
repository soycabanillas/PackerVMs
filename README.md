# Packer images for homelab

## Status
The templates are very customized to my needs. This is something that I will work on. For example, the connection through ssh uses my public ssh key, so it's not going to work for you unless you change the public ssh key (user-data) and the private ssh key (template.pkr.hcl). 
I'm not by any means a Linux expert and my experience with VMs is very limited. Improvements are welcome and I will help into adding them to this repository if they are sound. If you find anything to improve, please let me know. There can be redundant configuration, lack of cleaning up and other problems with this templates. 

## VS Code configuration
At this time I'm not using any configuration/extension specific to VS Code.

## Create templates
Before creating an image template, you will have to change the credentials.pkr.hcl file with your own credentials.
* The following instructions are using a file (credentials.pkr.hcl) to provide varibles to Packer templates, but you can use any supported way of providing variables to Packer. For a beginner user like myself is easier to change the file and test the images.
* The Infisical instructions are not intended to be used by anybody except me, as the .infisical.json file is pointing to my Infisical account. I'm currently using Infisical to manage the secrets I use in my homelab.

### Ubuntu Server Focal (20.04.06)
From ubuntu-server-focal folder:
```sh
packer init
packer build --var-file=../credentials.pkr.hcl template.pkr.hcl

if using Infisical:
infisical run --path="/Canvas" -- packer build  template.pkr.hcl
```
### Ubuntu Server Jammy (22.04.4)
From ubuntu-server-jammy folder:
```sh
packer init
packer build --var-file=../credentials.pkr.hcl template.pkr.hcl
```
### Ubuntu Server Noble (24.04)
From ubuntu-server-noble folder:
```sh
packer init
packer build --var-file=../credentials.pkr.hcl template.pkr.hcl
```
### Instructure Canvas (Ubuntu Server Focal 20.04.06)
From instructure-canvas folder:
```sh
packer init
packer build --var-file=../credentials.pkr.hcl template.pkr.hcl
```


### Related documentation

#### Packer templates
[HCL Templates Overview](https://developer.hashicorp.com/packer/docs/templates/hcl_templates)
#### Cloud-init Ubuntu
[Ubuntu installation documentation - Autoinstall](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)