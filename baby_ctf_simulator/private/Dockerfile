FROM archlinux as builder

RUN pacman -Sy --noconfirm base-devel clang 
RUN mkdir /build
ADD *.c *.h *.cpp *.hpp *.py Makefile /build/
WORKDIR /build
RUN make

FROM archlinux
COPY --from=builder /build/chall /chall
ADD flag.txt /flag
ENTRYPOINT [ "/chall" ]