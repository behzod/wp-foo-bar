#!/bin/bash
# Usage: ./foo-bar/init-plugin.sh "Hello World"
# Creates a directory "hello-world" in the current working directory,
# performing substitutions on the scaffold "foo-bar" plugin at https://github.com/xwp/wp-foo-bar

set -e

if [ $# != 1 ]; then
	echo "You must only supply one argument, the plugin name."
	exit 1
fi

name="$1"
if [ -z "$name" ]; then
	echo "Provide name argument"
	exit 1
fi

valid="^[A-Z][a-z0-9]*( [A-Z][a-z0-9]*)*$"
if [[ ! "$name" =~ $valid ]]; then
	echo "Malformed name argument '$name'. Please use title case words separated by spaces. No hyphens."
	exit 1
fi

slug="$( echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' )"
prefix="$( echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g' )"
namespace="$( echo "$name" | sed 's/ //g' )"
class="$( echo "$name" | sed 's/ /_/g' )"

cwd="$(pwd)"
cd "$(dirname "$0")"
src_repo_path="$(pwd)"
cd "$cwd"

if [[ -e $( basename "$0" ) ]]; then
	echo "Moving up one directory outside of foo-bar"
	cd ..
fi

if [ -e "$slug" ]; then
	echo "The $slug directory already exists"
	exit
fi

echo "Name: $name"
echo "Slug: $slug"
echo "Prefix: $prefix"
echo "NS: $namespace"
echo "Class: $class"

git clone "$src_repo_path" "$slug"

cd "$slug"

if git submodule update --init; then
	# Update dev-lib to latest
	cd dev-lib
	git pull origin master
	cd ..
else
	echo 'Failed to init submodules'
fi

git mv foo-bar.php "$slug.php"
cd tests
git mv test-foo-bar.php "test-$slug.php"
cd ..

git grep -lz "Foo Bar" | xargs -0 sed -i '' -e "s/Foo Bar/$name/g"
git grep -lz "foo-bar" | xargs -0 sed -i '' -e "s/foo-bar/$slug/g"
git grep -lz "foo_bar" | xargs -0 sed -i '' -e "s/foo_bar/$prefix/g"
git grep -lz "FooBar" | xargs -0 sed -i '' -e "s/FooBar/$namespace/g"
git grep -lz "Foo_Bar" | xargs -0 sed -i '' -e "s/Foo_Bar/$class/g"

if [ -e phpunit.xml.dist ]; then
    # sed destroys the symlink
    git checkout phpunit.xml.dist
fi

git remote set-url origin "https://github.com/xwp/wp-$slug.git"
if [ -e init-plugin.sh ]; then
	git rm -f init-plugin.sh
fi
git add -A .
git reset --soft $( git rev-list HEAD | tail -n 1 )
git commit --amend -m "Initial commit"

echo "Plugin is located at:"
pwd
