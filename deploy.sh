#!/bin/bash
set -e

usage()
{
	echo "Usage: $1 [--dont-build] [BUILD_ID]"
	echo "  --dont-build       Dont build."
	echo "  BUILD_ID           Git tag used."
}

DONT_BUILD=0
export BUILD_ID=
for opt; do
	case $opt in
		-h|--help) usage; exit 0 ;;
		--dont-build) DONT_BUILD=1 ;;
		*)
			if [ -n "$BUILD_ID" ]; then
				usage
				exit 1
			fi
			BUILD_ID="$1"
	esac
	shift
done

if ! git branch --no-color | grep -q '* source'; then
	echo Must deploy only from branch source
	exit 1
fi

[ -n "$BUILD_ID" ] || BUILD_ID=build-`date +%Y%m%d%H%M%S`

if git tag|grep -q "^$BUILD_ID$"; then
	echo Git tag already exists: $BUILD_ID
	exit 1
fi

if [ "$DONT_BUILD" == 0 ]; then
	./build.sh
fi

set -xu

# ensure we dont lose a bit
git commit -a || true
git tag "source-$BUILD_ID"

# push latests changes
git push origin source
git push origin "source-$BUILD_ID"

# prepare master to push
git checkout master
rm -rf .build
mv build .build
rm -rf *  # dont remove .build
mv -v .build/* .
find . -name '*.swp' -exec rm -f {} \;
rmdir .build

# add latests build and tag it
git add .
git commit -a -m "$BUILD_ID" || true
git tag "$BUILD_ID"

# push this build
git push origin master
git push origin "$BUILD_ID"

echo You are now on branch:
git checkout source