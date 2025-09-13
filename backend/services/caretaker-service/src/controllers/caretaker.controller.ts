import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CaretakerService } from '../services/caretaker.service';
import { CreateCaretakerDto, UpdateCaretakerDto, CaretakerResponseDto, PaginationDto } from '@baribhara/shared-types';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';

@ApiTags('caretakers')
@Controller('caretakers')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CaretakerController {
  constructor(private readonly caretakerService: CaretakerService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new caretaker profile' })
  @ApiResponse({ status: 201, description: 'Caretaker profile successfully created', type: CaretakerResponseDto })
  @ApiResponse({ status: 400, description: 'Bad request' })
  async create(@Body() createCaretakerDto: CreateCaretakerDto): Promise<CaretakerResponseDto> {
    return this.caretakerService.create(createCaretakerDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all caretakers with pagination' })
  @ApiResponse({ status: 200, description: 'Caretakers retrieved successfully' })
  async findAll(@Query() paginationDto: PaginationDto) {
    return this.caretakerService.findAll(paginationDto);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search caretakers' })
  @ApiResponse({ status: 200, description: 'Caretakers found' })
  async search(
    @Query('query') query: string,
    @Query('city') city?: string,
    @Query('district') district?: string,
    @Query('type') type?: string,
    @Query('specialties') specialties?: string,
    @Query('minRating') minRating?: number,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.caretakerService.search({
      query,
      city,
      district,
      type,
      specialties: specialties ? specialties.split(',') : undefined,
      minRating,
      page,
      limit,
    });
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get caretaker by user ID' })
  @ApiResponse({ status: 200, description: 'Caretaker retrieved successfully', type: CaretakerResponseDto })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async findByUserId(@Param('userId') userId: string): Promise<CaretakerResponseDto> {
    return this.caretakerService.findByUserId(userId);
  }

  @Get('verified')
  @ApiOperation({ summary: 'Get verified caretakers' })
  @ApiResponse({ status: 200, description: 'Verified caretakers retrieved successfully' })
  async findVerified(@Query() paginationDto: PaginationDto) {
    return this.caretakerService.findVerified(paginationDto);
  }

  @Get('top-rated')
  @ApiOperation({ summary: 'Get top-rated caretakers' })
  @ApiResponse({ status: 200, description: 'Top-rated caretakers retrieved successfully' })
  async findTopRated(@Query('limit') limit: number = 10) {
    return this.caretakerService.findTopRated(limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get caretaker by ID' })
  @ApiResponse({ status: 200, description: 'Caretaker retrieved successfully', type: CaretakerResponseDto })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async findOne(@Param('id') id: string): Promise<CaretakerResponseDto> {
    return this.caretakerService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update caretaker profile' })
  @ApiResponse({ status: 200, description: 'Caretaker updated successfully', type: CaretakerResponseDto })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async update(@Param('id') id: string, @Body() updateCaretakerDto: UpdateCaretakerDto): Promise<CaretakerResponseDto> {
    return this.caretakerService.update(id, updateCaretakerDto);
  }

  @Put(':id/verify')
  @ApiOperation({ summary: 'Verify caretaker profile' })
  @ApiResponse({ status: 200, description: 'Caretaker verified successfully' })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async verify(@Param('id') id: string): Promise<{ message: string }> {
    await this.caretakerService.verify(id);
    return { message: 'Caretaker verified successfully' };
  }

  @Put(':id/suspend')
  @ApiOperation({ summary: 'Suspend caretaker' })
  @ApiResponse({ status: 200, description: 'Caretaker suspended successfully' })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async suspend(@Param('id') id: string): Promise<{ message: string }> {
    await this.caretakerService.suspend(id);
    return { message: 'Caretaker suspended successfully' };
  }

  @Put(':id/activate')
  @ApiOperation({ summary: 'Activate caretaker' })
  @ApiResponse({ status: 200, description: 'Caretaker activated successfully' })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async activate(@Param('id') id: string): Promise<{ message: string }> {
    await this.caretakerService.activate(id);
    return { message: 'Caretaker activated successfully' };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete caretaker profile' })
  @ApiResponse({ status: 200, description: 'Caretaker deleted successfully' })
  @ApiResponse({ status: 404, description: 'Caretaker not found' })
  async remove(@Param('id') id: string): Promise<{ message: string }> {
    await this.caretakerService.remove(id);
    return { message: 'Caretaker deleted successfully' };
  }
}
