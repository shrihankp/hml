echo "Downloading the patcher files..."
curl -Lo patcher.sh "https://raw.githubusercontent.com/shrihanDev/hml/master/patcher.sh"
curl -Lo ubuntu.sh "https://raw.githubusercontent.com/shrihanDev/hml/master/ubuntu.sh"
mkdir util
curl -Lo util/logging.sh "https://raw.githubusercontent.com/shrihanDev/hml/master/util/logging.sh"
curl -Lo util/try-catch.sh "https://raw.githubusercontent.com/shrihanDev/hml/master/util/try-catch.sh"
echo "Done! Starting the patcher!"
chmod +x patcher.sh
exec ./patcher.sh
