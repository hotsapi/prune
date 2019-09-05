FROM node:11

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .

CMD ["node", "main.js"]
