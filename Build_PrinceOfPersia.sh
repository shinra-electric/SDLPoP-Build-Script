#!/usr/bin/env zsh

# ANSI colour codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

# This gets the location of the folder where the script is run from. 
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

echo "\n${PURPLE}This script is for compiling a native macOS build of:"
echo "${GREEN}Prince of Persia${PURPLE} DOS Edition"

echo "\n${PURPLE}The source code used is from a project called ${GREEN}SDLPoP${NC}\n"

ARCH_NAME="$(uname -m)"
echo "${PURPLE}Your CPU architecture is ${GREEN}${ARCH_NAME}${PURPLE}, so the app can only be run on Macs with a ${GREEN}${ARCH_NAME}${PURPLE} CPU${NC}"

echo "\n${PURPLE}${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required to build${NC}"
echo "${PURPLE}If they are not present you will be prompted to install them${NC}\n"

PS3='Would you like to continue? '
OPTIONS=(
	"Yes"
	"Quit")
select opt in $OPTIONS[@]
do
	case $opt in
		"Yes")
			break
			;;
		"Quit")
			echo -e "${RED}Quitting${NC}"
			exit 0
			;;
		*) 
			echo "\"$REPLY\" is not one of the options..."
			echo "Enter the number of the option and press enter to select"
			;;
	esac
done

# Check if Homebrew is installed
echo "${PURPLE}Checking for Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
	echo -e "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if [[ "${ARCH_NAME}" == "arm64" ]]; then 
		(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
		eval "$(/opt/homebrew/bin/brew shellenv)"
		else 
		(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> $HOME/.zprofile
		eval "$(/usr/local/bin/brew shellenv)"
	fi
	
	# Check for errors
	if [ $? -ne 0 ]; then
		echo "${RED}There was an issue installing Homebrew${NC}"
		echo "${PURPLE}Quitting script...${NC}"	
		exit 1
	fi
else
	echo -e "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
	brew update
fi

## Homebrew dependencies
echo -e "${PURPLE}Checking for Homebrew dependencies...${NC}"
brew_dependency_check() {
	if [ -d "$(brew --prefix)/opt/$1" ]; then
		echo -e "${GREEN}Found $1. Checking for updates...${NC}"
			brew upgrade $1
	else
		 echo -e "${PURPLE}Did not find $1. Installing...${NC}"
		brew install $1
	fi
}

# Required Homebrew packages
deps=( dylibbundler sdl2 sdl2_image pkg-config )

for dep in $deps[@]
do 
	brew_dependency_check $dep
done

# Get the repository
git clone --recursive https://github.com/NagyD/SDLPoP
cd SDLPoP/src

# Build 
make

# Move back to the main directory
cd ..

# Create app bundle structure
rm -rf Prince\ of\ Persia.app
mkdir -p Prince\ of\ Persia.app/Contents/Resources
mkdir -p Prince\ of\ Persia.app/Contents/MacOS

# create Info.plist
PLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
  	<key>CFBundleGetInfoString</key>
  	<string>Prince Of Persia</string>
	<key>CFBundleExecutable</key>
	<string>prince</string>
	<key>CFBundleIconFile</key>
	<string>prince.icns</string>
	<key>CFBundleIdentifier</key>
	<string>org.princed.PrinceOfPersia</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Prince of Persia</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.23</string>
	<key>CFBundleVersion</key>
	<string>1.23</string>
	<key>LSMinimumSystemVersion</key>
	<string>11.0</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSHumanReadableCopyright</key>
	<string>GNU General Public Licence, v3</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>CSResourcesFileMapped</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<false/>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.games</string>
</dict>
</plist>
"
echo "${PLIST}" > "Prince of Persia.app/Contents/Info.plist"

# Create PkgInfo
PKGINFO="-n APPLPROP"
echo "${PKGINFO}" > "Prince of Persia.app/Contents/PkgInfo"

# Bundle resources. 
cp -R prince data mods replays SDLPoP.ini Prince\ of\ Persia.app/Contents/MacOS/

if [[ -a prince1024.png ]]; then 
	# Create icon if there is a file called prince1024.png in the build folder
	echo -e "${PURPLE}Found image file. Creating icon...${NC}"
	
	# mkdir ${GAME_ID}.iconset
	mkdir prince.iconset
	sips -z 16 16     prince1024.png --out prince.iconset/icon_16x16.png
	sips -z 32 32     prince1024.png --out prince.iconset/icon_16x16@2x.png
	sips -z 32 32     prince1024.png --out prince.iconset/icon_32x32.png
	sips -z 64 64     prince1024.png --out prince.iconset/icon_32x32@2x.png
	sips -z 128 128   prince1024.png --out prince.iconset/icon_128x128.png
	sips -z 256 256   prince1024.png --out prince.iconset/icon_128x128@2x.png
	sips -z 256 256   prince1024.png --out prince.iconset/icon_256x256.png
	sips -z 512 512   prince1024.png --out prince.iconset/icon_256x256@2x.png
	sips -z 512 512   prince1024.png --out prince.iconset/icon_512x512.png
	cp prince1024.png prince.iconset/icon_512x512@2x.png
	iconutil -c icns prince.iconset
	rm -R prince.iconset
	cp -R prince.icns Prince\ of\ Persia.app/Contents/Resources/

	else 
	
	# Otherwise get an icon from macosicons.com
	echo -e "Did not find an image to use as an icon, so downloading one from www.macosicons.com"
	curl -o Prince\ of\ Persia.app/Contents/Resources/prince.icns https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/ffa5a831ccc8b26f9e902d55a8880212_uxMH2QAFqE.icns
fi

# Get an updated version of the game controller database
echo -e "Getting an updated SDL game controller DB file...."
curl -o Prince\ of\ Persia.app/Contents/MacOS/gamecontrollerdb.txt https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/master/gamecontrollerdb.txt
# Remove the semicolon from the ini file that is commenting out the use of the game controller DB
sed -i '' "s/;gamecontrollerdb_file = gamecontrollerdb.txt/gamecontrollerdb_file = gamecontrollerdb.txt/g" Prince\ of\ Persia.app/Contents/MacOS/SDLPoP.ini

# Bundle libs & Codesign
dylibbundler -of -cd -b -x ./Prince\ of\ Persia.app/Contents/MacOS/prince -d ./Prince\ of\ Persia.app/Contents/libs/

cp -R Prince\ of\ Persia.app ..
cd ..
rm -rf SDLPoP
