import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { PropertyService } from '../services/property.service';
import { CreatePropertyDto, UpdatePropertyDto, PropertyResponseDto, PaginationDto } from '@baribhara/shared-types';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';

@ApiTags('properties')
@Controller('properties')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PropertyController {
  constructor(private readonly propertyService: PropertyService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new property' })
  @ApiResponse({ status: 201, description: 'Property successfully created', type: PropertyResponseDto })
  @ApiResponse({ status: 400, description: 'Bad request' })
  async create(@Body() createPropertyDto: CreatePropertyDto): Promise<PropertyResponseDto> {
    return this.propertyService.create(createPropertyDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all properties with pagination' })
  @ApiResponse({ status: 200, description: 'Properties retrieved successfully' })
  async findAll(@Query() paginationDto: PaginationDto) {
    return this.propertyService.findAll(paginationDto);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search properties' })
  @ApiResponse({ status: 200, description: 'Properties found' })
  async search(
    @Query('query') query: string,
    @Query('city') city?: string,
    @Query('district') district?: string,
    @Query('type') type?: string,
    @Query('minRent') minRent?: number,
    @Query('maxRent') maxRent?: number,
    @Query('minBedrooms') minBedrooms?: number,
    @Query('maxBedrooms') maxBedrooms?: number,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.propertyService.search({
      query,
      city,
      district,
      type,
      minRent,
      maxRent,
      minBedrooms,
      maxBedrooms,
      page,
      limit,
    });
  }

  @Get('caretaker/:caretakerId')
  @ApiOperation({ summary: 'Get properties by caretaker' })
  @ApiResponse({ status: 200, description: 'Properties retrieved successfully' })
  async findByCaretaker(
    @Param('caretakerId') caretakerId: string,
    @Query() paginationDto: PaginationDto,
  ) {
    return this.propertyService.findByCaretaker(caretakerId, paginationDto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get property by ID' })
  @ApiResponse({ status: 200, description: 'Property retrieved successfully', type: PropertyResponseDto })
  @ApiResponse({ status: 404, description: 'Property not found' })
  async findOne(@Param('id') id: string): Promise<PropertyResponseDto> {
    return this.propertyService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update property' })
  @ApiResponse({ status: 200, description: 'Property updated successfully', type: PropertyResponseDto })
  @ApiResponse({ status: 404, description: 'Property not found' })
  async update(@Param('id') id: string, @Body() updatePropertyDto: UpdatePropertyDto): Promise<PropertyResponseDto> {
    return this.propertyService.update(id, updatePropertyDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete property' })
  @ApiResponse({ status: 200, description: 'Property deleted successfully' })
  @ApiResponse({ status: 404, description: 'Property not found' })
  async remove(@Param('id') id: string): Promise<{ message: string }> {
    await this.propertyService.remove(id);
    return { message: 'Property deleted successfully' };
  }
}
