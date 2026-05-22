root-dir := justfile_directory()
occt-version := "8.0.0"
occt-url := "https://github.com/Open-Cascade-SAS/OCCT/archive/refs/tags/V8_0_0.tar.gz"
occt-tarball := root-dir + "/.local/occt.tar.gz"
occt-src := root-dir + "/.local/occt-src"
occt-build := root-dir + "/.local/occt-build"
occt-install := root-dir + "/.local"
clocct-dir := root-dir + "/lib/cl-occt"

default:
    @echo "cl-occt-viewer (Qt) — Common Lisp parametric CAD with 3D viewer"
    @echo ""
    @echo "Recipes:"
    @echo "  setup        Download + build OCCT {{occt-version}} (one-time)"
    @echo "  submodules         Init submodule + symlink + wrap (requires OCCT built)"
    @echo "  viewer       Build shared library → lib/libocctviewer.so"
    @echo "  core         Build SBCL core dump → ClotCAD.core"
    @echo "  dist         Assemble distribution → dist/ + tarball + AppImage"
    @echo "  package-all  viewer + core + dist (run setup first)"
    @echo "  start        Launch viewer + Swank SLIME server"
    @echo "  test         Run Lisp test suite"
    @echo "  clean        Remove build artifacts"

setup:
    # Download and build OCCT 8.0.0
    mkdir -p {{occt-install}}
    curl -Lo {{occt-tarball}} {{occt-url}}
    mkdir -p {{occt-src}}
    tar xzf {{occt-tarball}} -C {{occt-src}} --strip-components=1
    rm -rf {{occt-build}}
    mkdir -p {{occt-build}}
    cd {{occt-build}} && cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX={{occt-install}} \
        -DBUILD_LIBRARY_TYPE=Shared \
        -DBUILD_MODULE_ApplicationFramework=OFF \
        -DBUILD_MODULE_DataExchange=ON \
        -DBUILD_MODULE_Draw=OFF \
        -DBUILD_MODULE_FoundationClass=ON \
        -DBUILD_MODULE_ModelingAlgorithms=ON \
        -DBUILD_MODULE_ModelingData=ON \
        -DBUILD_MODULE_Visualization=ON \
        {{occt-src}}
    cmake --build {{occt-build}} -- -j$(nproc)
    cmake --install {{occt-build}}
    # Init submodule and build cl-occt's C wrapper
    git submodule update --init {{clocct-dir}}
    ln -sf ../../.local {{clocct-dir}}/.local
    cd {{clocct-dir}} && just wrap

submodules:
    test -f {{occt-install}}/lib/libTKernel.so || (echo "OCCT not built — run 'just setup' first" && exit 1)
    git submodule update --init {{clocct-dir}}
    ln -sf ../../.local {{clocct-dir}}/.local
    cd {{clocct-dir}} && just wrap

viewer:
    mkdir -p build lib
    cmake -S . -B build -DOCCT_DIR={{occt-install}}
    cmake --build build -- -j$(nproc)
    cp build/libocctviewer.so lib/

core:
    LD_LIBRARY_PATH=lib:{{occt-install}}/lib:{{clocct-dir}}/lib \
    sbcl --script scripts/make-core.lisp

dist:
    ./scripts/package.sh

package-all: submodules viewer core dist

start:
    LD_LIBRARY_PATH=lib:{{occt-install}}/lib:{{clocct-dir}}/lib \
    sbcl --script scripts/start.lisp

test:
    LD_LIBRARY_PATH=lib:{{occt-install}}/lib:{{clocct-dir}}/lib \
    sbcl --noinform --quit \
      --eval '(require :asdf)' \
      --eval '(push "{{clocct-dir}}/" asdf:*central-registry*)' \
      --eval '(push "{{root-dir}}/" asdf:*central-registry*)' \
      --eval '(asdf:load-system :cl-occt-viewer/tests :force t)' \
      --eval '(in-package :cl-occt-viewer)' \
      --eval '(run-tests)' \
      --eval '(sb-ext:quit)'

clean:
    rm -rf build lib
