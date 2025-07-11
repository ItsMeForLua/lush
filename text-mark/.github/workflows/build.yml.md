# .github/workflows/build.yml

```yml
name: Build and Test

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y lua5.4 liblua5.4-dev

      - name: Install Premake
        run: |
          PREMAKE_VERSION="5.0.0-beta2"
          OS="linux"
          wget -q https://github.com/premake/premake-core/releases/download/v${PREMAKE_VERSION}/premake-${PREMAKE_VERSION}-${OS}.tar.gz -O premake.tar.gz
          tar -xzf premake.tar.gz
          sudo mv premake5 /usr/bin
          sudo chmod +x /usr/bin/premake5
          rm premake.tar.gz

      - name: Generate Makefile with Premake
        run: premake5 gmake

      - name: Build project
        run: make

      - name: Install shell program
        run: |
          if [ ! -d ~/.lush ]; then
            cp -rf ./.lush ~/
          fi

          sudo cp ./bin/Debug/lush/lush /usr/bin/lush.new
          sudo mv /usr/bin/lush.new /usr/bin/lush
          
          # Ensure the shell is registered in /etc/shells
          if ! grep -Fxq "/usr/bin/lush" /etc/shells; then
            echo "/usr/bin/lush" | sudo tee -a /etc/shells >/dev/null
          fi  

      - name: Run Lua tests
        run: |
          cd test
          lush run_tests.lua

      - name: Upload the compiled binary
        uses: actions/upload-artifact@v4
        with:
          name: lush-binary
          path: ./bin/Debug/lush/lush

```
