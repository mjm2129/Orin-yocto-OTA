OTA - Update Layer in AGX ORIN

<img width="959" height="630" alt="Image" src="https://github.com/user-attachments/assets/6926f6a6-a2fb-4af8-9b65-e3faeb294970" />




<img width="1226" height="608" alt="Image" src="https://github.com/user-attachments/assets/7c41e7b8-cea1-4f62-bab8-397ca084214d" />







How to set up 

refer Document 
https://github.com/mjm2129/Orin-yocto-OTA/blob/main/Setting%20Guide.pdf




In Cloud -> Ncloud 저장소 구성 (5개의 디렉토리를 만들어야 함)

In Host -> Yocto layer 구성 파일. 

!!! 숨김 파일이 있어, 파일명 맨 앞에1을 붙여놨습니다. s3cmd-master 디렉토리에서 1로 시작하는 모든 파일들에게서 1을 제거하세요. (example : 1.ci.svnignore 파일 이름을 .ci.svnignore로 변경)




In Orin -> Orin에서 실행되는 스크립트 및 desktop file

=========================================================================================

사용 가이드


1. 클라우드에서 ota_option.conf 에 옵션이 있습니다. OTA_enabled가 true라면 자동 업데이트를 진행하고, false라면 업데이트 없이 와이파이와 클라우드 셋업만 진행됩니다.
   만약 업데이트를 진행하고 싶지 않은 경우, 옵션을 false로 설정하세요.

2. 클라우드에서 ota_package 디렉토리는 Orin 기기에 플래싱 할 이미지가 업로드되어야 하는데, yocto_rootfs.ext4.gz 파일명으로 업로드되어야 합니다. Yocto 이미지를 빌드한 이후, rootfs.ext4를 압축하고 이름을 맞게 지정하세요
   info) yocto rootfs는 기본 설정 크기가 28GB로 되어있어, 그냥 이미지만 압축하여 올리게 되면, 업로드 및 업데이트에도 시간이 오래 걸립니다.
         빌드한 이미지에 대해서 e2fsck, resize 명령어를 사용해서 이미지 크기를 최소화 하여 업로드하면, Orin 기기에서 업데이트 시간이 매우 빠릅니다.
