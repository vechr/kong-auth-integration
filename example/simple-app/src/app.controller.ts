import { Controller, Get, Req } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getHeaders(@Req() request: Request) {
    return request.headers;
  }
}
