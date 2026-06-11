FROM node:20-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci
COPY . .

EXPOSE 3000

CMD ["sh", "-c", "npx prisma generate && node index.js"]