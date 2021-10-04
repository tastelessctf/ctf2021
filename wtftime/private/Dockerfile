FROM node
RUN mkdir /chall/
WORKDIR /chall/
ADD package.json /chall/
RUN npm install
ADD ./tsconfig.json ./tslint.json /chall/
ADD ./src /chall/src/
ADD ./migrations /chall/migrations/
RUN npm run build
ADD ./app /chall/app
WORKDIR /chall/app/
RUN npm install
RUN npm run build
ADD ./run.sh /chall/run.sh

WORKDIR /chall/
EXPOSE 3000
ENTRYPOINT [ "./run.sh" ]
