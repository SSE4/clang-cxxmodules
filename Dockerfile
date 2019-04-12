FROM debian:stretch

LABEL maintainer="SSE4 <tomskside@gmail.com>"

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    ca-certificates \
    git \
    unzip \
    python3 && \
    curl -sL https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1-Linux-x86_64.tar.gz | tar -xz && \
    curl -sL https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-linux.zip -o ninja-linux.zip && \
    unzip ninja-linux.zip -d ninja-linux && \
    chmod +x ninja-linux/ninja && \
    rm -f ninja-linux.zip

ENV PATH=$PATH:/ninja-linux:/cmake-3.14.1-Linux-x86_64/bin

RUN git clone --depth 1 https://github.com/llvm/llvm-project.git && \
    cd llvm-project && \
    mkdir build && \
    cd build && \
    cmake -G Ninja ../llvm \
    -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/host/clang \
    -DLLVM_ENABLE_ASSERTIONS=OFF && \
    cmake --build .  -- -j1 && \
    cmake --build . --target install && \
    cmake --build . --target cxx -- -j1 && \
    cmake --build . --target install-cxx && \
    cmake --build . --target cxxabi -- -j1 && \
    cmake --build . --target install-cxxabi

FROM debian:stretch

COPY --from=0 /host/clang /host/clang

RUN ln -s /host/clang/bin/clang /usr/bin/clang && \
    ln -s /host/clang/bin/clang++ /usr/bin/clang++ && \
    echo "/host/clang/lib" > /etc/ld.so.conf.d/libc++.conf && ldconfig && \
    apt-get update -y && \
    apt-get install --no-install-recommends -y \
    libc6-dev \
    libgcc-6-dev \
    binutils
