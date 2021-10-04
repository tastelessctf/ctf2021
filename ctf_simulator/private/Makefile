# For some reason, -Os is necessary to put some variables on the stack in check_flag.
CXXFLAGS=-fomit-frame-pointer -fstack-protector
CFLAGS=-fomit-frame-pointer -fstack-protector-all -Os
CXX=clang++
CC=clang

DOCKER=docker
DOCKERTAG=ctfsim2

all: chall poc

chall: chall.o Exceptions.o ostream.o bug.o 
	$(CXX) -Wl,--wrap=__stack_chk_fail -fuse-ld=gold -flto -Wl,--no-pic-executable -Wl,-Ttext=0xa0000 -o $@ chall.o Exceptions.o ostream.o bug.o 
	#strip $@

poc: poc.o
	$(CXX) -Wl,--wrap=__stack_chk_fail -fuse-ld=gold -flto -Wl,--no-pic-executable -o $@ $^

.PHONY: publish
publish: docker ../public/chall ../public/libc-2.33.so

.PHONY: docker
docker: Dockerfile
	$(DOCKER) build -t $(DOCKERTAG) .

../public/chall: docker
	CONTAINER=$$($(DOCKER) create $(DOCKERTAG)) \
	&& $(DOCKER) cp $$CONTAINER:/chall ../public/ \
	&& $(DOCKER) rm $$CONTAINER

../public/libc-2.33.so: docker
	CONTAINER=$$($(DOCKER) create $(DOCKERTAG)) \
	&& $(DOCKER) cp $$CONTAINER:/usr/lib/libc-2.33.so ../public/ \
	&& $(DOCKER) rm $$CONTAINER

.PHONY: clean
clean:
	rm -f chall *.o poc
