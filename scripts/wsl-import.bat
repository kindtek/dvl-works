@echo off
SETLOCAL EnableDelayedExpansion
:redo
@REM set default variables. set default literally to default
SET default=default

SET image_repo=kindtek
SET image_name=dbp:ubuntu-phat
SET mount_drive=C
SET "install_directory=%image_name::=-%"
SET save_directory=docker

SET "save_location=%mount_drive%:\%save_directory%"
SET "install_location=%save_location%\%install_directory%"
SET "distro=%image_name::=-%"
:header
SET save_location=%mount_drive%:\%save_directory%
SET image_save_path=%save_location%\%distro%.tar
SET "install_location=%save_location%\%image_name::=-%"
SET image_repo_and_name=%image_repo%/%image_name%
SET docker_image_id_path=%install_location%\.image_id
SET docker_container_id_path=%install_location%\.container_id
SET image_tag=%image_name:*:=%

CLS
ECHO:
ECHO  ___________________________________________________________________ 
ECHO /                          DEV BOILERPLATE                          \
ECHO \___________________    WSL image import tool    ___________________/
ECHO   .................................................................
ECHO   .............    Default options in (parentheses)   .............
ECHO   .................................................................

IF %default%==config ( goto custom_config )

IF "%default%"=="" ( 
    default=confirm
    goto confirm
)

@REM default equals default if first time around
IF %default%==notdefault ( 
    default=defnotdefault
    goto confirm 
)

IF %default%==defnotdefault ( 
    goto confirm
)

IF NOT %default%==default (goto %default%)

ECHO:
ECHO:
ECHO Press ENTER to import %image_repo_and_name% as default WSL distro 
ECHO:
ECHO ..or type "config" for custom install.
ECHO:
ECHO:
SET /p "default=(Start default install) > "

@REM catch when default configs NOT chosen AND second time around for user who chose to customize
@REM display header but skip prompt when user chooses to customize install
@REM IF %default%==config ( goto header )

:custom_config

if %default%==config (

ECHO:
SET /p "image_repo=image repository: (!image_repo!) > "
SET /p "image_name=image name in !image_repo!: (!image_name!) > "
SET "image_repo_and_name=!image_repo!/!image_name!"
SET /p "save_directory=download folder: !mount_drive!:\(!save_directory!) > "

SET /p "install_directory=install folder: !mount_drive!:\!save_directory!\(!image_repo_and_name::=-!) > "
@REM not possible to set this above bc it will overlap with the default initializing so set it here
SET install_directory=!install_directory::=-!
SET save_location=!mount_drive!:\!save_directory!
SET install_location=!save_location!\!install_directory!

ECHO Save image as:
SET "distro=!image_name::=-!"
SET /p "distro=!install_location!\(!distro!).tar > "
SET "distro=!distro::=-!"

)

@REM directory structure: 
@REM %mount_drive%:\%install_directory%\%save_directory%
@REM ie: C:\wsl-distros\docker

@REM below is for debug ..TODO: comment out eventually
ECHO:
ECHO setting up save directory (!save_directory!)...
mkdir !save_location!
ECHO:
ECHO setting up install directory (!install_directory!)...
mkdir !install_location!

:confirm
ECHO ---------------------------------------------------------------------
wsl --list
ECHO ---------------------------------------------------------------------
ECHO Check the list of current WSL distros installed on your system above. 
ECHO If !distro! is already listed above it will be REPLACED.
ECHO Use CTRL-C to quit now if this is not what you want.
ECHO _____________________________________________________________________
ECHO =====================================================================
ECHO CONFIRM YOUR SETTINGS

SET image_repo_image_name=!image_repo!/!image_name!
ECHO image source/name: !image_repo_image_name!
SET image_save_path=!save_location!\!distro!.tar
ECHO image destination: !image_save_path!
ECHO WSL alias : !distro! 
ECHO -----------------------------------------------------------------------------------------------------

ECHO =====================================================================================================
ECHO pulling image (!image_repo_image_name!)...
@REM pull the image
docker pull !image_repo_image_name!
ECHO initializing the image container
ECHO !image_tag!
docker images -aq !image_repo_image_name! > !docker_image_id_path!
SET /P _WSL_DOCKER_IMG_ID=<!docker_image_id_path!

del !docker_container_id_path!
docker run -dit --cidfile !docker_container_id_path! !_WSL_DOCKER_IMG_ID! 

@REM ECHO !docker_container_id_path!
@REM set /p _WSL_DOCKER_IMG_ID=<docker ps -alq !image_repo!:!image_tag!
 
@REM SET /p _WSL_DOCKER_IMG_ID=(imageid_!_WSL_DOCKER_IMG_ID!)
SET /P _WSL_DOCKER_CONTAINER_ID=<!docker_container_id_path!

docker export !_WSL_DOCKER_CONTAINER_ID! > "!image_save_path!"
ECHO DONE

:install_prompt
ECHO:
ECHO Would you still like to continue (yes/no/redo)?
SET /p "continue="

@REM if blank -> yes 
IF "%continue%"=="" ( 
    SET continue=yes
)

@REM if y -> yes 
IF %continue%==y ( 
    SET continue=yes
)

@REM if n -> yes no
IF %continue%==n ( 
    SET continue=no
)

@REM if label exists goto it
goto %continue%

@REM otherwise... use the built in error message and repeat install prompt
goto install_prompt

@REM EASTER EGG: typing yes at first prompt bypasses cofirm and restart the default distro
:yes
:install
ECHO:
ECHO killing the !distro! WSL process if it is running...
wsl --terminate !distro!
ECHO DONE
@REM ECHO:
@REM ECHO killing all WSL processes...
@REM wsl --shutdown
@REM ECHO DONE

if NOT default==yes (
    ECHO deleting WSL distro !distro! if it exists...
    wsl --unregister !distro!
    ECHO DONE
)

ECHO:
ECHO importing  !distro!.tar to !install_location! as !distro!
wsl --import !distro! !install_location! !image_save_path!
ECHO DONE


if NOT default==yes (
    ECHO:
    ECHO setting !distro! as default
    wsl --set-default !distro!
    ECHO DONE
)

@REM wsl --shutdown
wsl -l -v
wsl 

:quit
:no
echo goodbye
