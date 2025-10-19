# OTA - Update Layer in AGX ORIN

<img width="959" height="630" alt="Image" src="https://github.com/user-attachments/assets/6926f6a6-a2fb-4af8-9b65-e3faeb294970" />

# System Layout
#### Whole Configuration is like this image.
#### In EMMC Partition, there is flashed Yocto Image.
#### In NVMe Partition, there is JetPack Linux, because Yocto doesn't need so much Disk space, and generally Users use much space in Jetson Linux.
#### ===========================================================================================


<img width="1226" height="608" alt="Image" src="https://github.com/user-attachments/assets/7c41e7b8-cea1-4f62-bab8-397ca084214d" />

# Process
#### whole Process is configured Three Step.
#### First, when you boot AGX Orin with Emmc(Yocto), System will automatically setup Network, syncronize Time with Cloud server, Check Yocto Image version. and, If you need update, Reboot process will begin. In this Process, system will write OTA log in Cloud.

#### Second, System will begin JetPack(NVMe), and check OTA log by downloading in cloud stroage. and Download OTA_Package (yocto rootfs). and start Update by using dd (disk dump) command. If succeed, You can check the success log in Cloud.

#### Third, System will boot Yocto(EMMc), and finally check whether update is applied safely or not. In these Process, if something weird (like network problem, power off ... etc) happens, You can see booting is not working. for that, Users can configure the option of back-up in Cloud. For more information, refer the setting Document.

=========================================================================================




# How to set up 

#### refer Document 
#### https://github.com/mjm2129/Orin-yocto-OTA/blob/main/Setting%20Guide.pdf
#### There are Command that can apply OTA Layer including Using Cloud.
=========================================================================================

# Directory Instruction 

#### In Cloud -> Ncloud 저장소 구성 
#### In Host -> Yocto layer 구성 파일. 
#### In Orin -> Orin에서 실행되는 스크립트 및 desktop file
### !!! 숨김 파일이 있어, 파일명 맨 앞에1을 붙여놨습니다. s3cmd-master 디렉토리에서 1로 시작하는 모든 파일들에게서 1을 제거하세요. (example : 1.ci.svnignore 파일 이름을 .ci.svnignore로 변경) !!!
### !!! There is some hidden file (starts name with '.'), so I renamed that files with '1.blah~~'. Delete '1' in Filename that starts with '1'.)
=========================================================================================

사용 가이드


1. 클라우드에서 ota_option.conf 에 옵션이 있습니다. OTA_enabled가 true라면 자동 업데이트를 진행하고, false라면 업데이트 없이 와이파이와 클라우드 셋업만 진행됩니다.
   만약 업데이트를 진행하고 싶지 않은 경우, 옵션을 false로 설정하세요.

2. 클라우드에서 ota_package 디렉토리는 Orin 기기에 플래싱 할 이미지가 업로드되어야 하는데, yocto_rootfs.ext4.gz 파일명으로 업로드되어야 합니다. Yocto 이미지를 빌드한 이후, rootfs.ext4를 압축하고 이름을 맞게 지정하세요
   info) yocto rootfs는 기본 설정 크기가 28GB로 되어있어, 그냥 이미지만 압축하여 올리게 되면, 업로드 및 업데이트에도 시간이 오래 걸립니다.
         빌드한 이미지에 대해서 e2fsck, resize 명령어를 사용해서 이미지 크기를 최소화 하여 업로드하면, Orin 기기에서 업데이트 시간이 매우 빠릅니다.
