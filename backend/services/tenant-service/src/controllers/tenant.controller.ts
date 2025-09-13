import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { TenantService } from '../services/tenant.service';
import { CreateTenantDto, UpdateTenantDto, TenantResponseDto, PaginationDto } from '@baribhara/shared-types';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';

@ApiTags('tenants')
@Controller('tenants')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class TenantController {
  constructor(private readonly tenantService: TenantService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new tenant profile' })
  @ApiResponse({ status: 201, description: 'Tenant profile successfully created', type: TenantResponseDto })
  @ApiResponse({ status: 400, description: 'Bad request' })
  async create(@Body() createTenantDto: CreateTenantDto): Promise<TenantResponseDto> {
    return this.tenantService.create(createTenantDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all tenants with pagination' })
  @ApiResponse({ status: 200, description: 'Tenants retrieved successfully' })
  async findAll(@Query() paginationDto: PaginationDto) {
    return this.tenantService.findAll(paginationDto);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search tenants' })
  @ApiResponse({ status: 200, description: 'Tenants found' })
  async search(
    @Query('query') query: string,
    @Query('city') city?: string,
    @Query('district') district?: string,
    @Query('type') type?: string,
    @Query('status') status?: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.tenantService.search({
      query,
      city,
      district,
      type,
      status,
      page,
      limit,
    });
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get tenant by user ID' })
  @ApiResponse({ status: 200, description: 'Tenant retrieved successfully', type: TenantResponseDto })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async findByUserId(@Param('userId') userId: string): Promise<TenantResponseDto> {
    return this.tenantService.findByUserId(userId);
  }

  @Get('property/:propertyId')
  @ApiOperation({ summary: 'Get tenants by property' })
  @ApiResponse({ status: 200, description: 'Tenants retrieved successfully' })
  async findByProperty(
    @Param('propertyId') propertyId: string,
    @Query() paginationDto: PaginationDto,
  ) {
    return this.tenantService.findByProperty(propertyId, paginationDto);
  }

  @Get('caretaker/:caretakerId')
  @ApiOperation({ summary: 'Get tenants by caretaker' })
  @ApiResponse({ status: 200, description: 'Tenants retrieved successfully' })
  async findByCaretaker(
    @Param('caretakerId') caretakerId: string,
    @Query() paginationDto: PaginationDto,
  ) {
    return this.tenantService.findByCaretaker(caretakerId, paginationDto);
  }

  @Get('verified')
  @ApiOperation({ summary: 'Get verified tenants' })
  @ApiResponse({ status: 200, description: 'Verified tenants retrieved successfully' })
  async findVerified(@Query() paginationDto: PaginationDto) {
    return this.tenantService.findVerified(paginationDto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get tenant by ID' })
  @ApiResponse({ status: 200, description: 'Tenant retrieved successfully', type: TenantResponseDto })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async findOne(@Param('id') id: string): Promise<TenantResponseDto> {
    return this.tenantService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update tenant profile' })
  @ApiResponse({ status: 200, description: 'Tenant updated successfully', type: TenantResponseDto })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async update(@Param('id') id: string, @Body() updateTenantDto: UpdateTenantDto): Promise<TenantResponseDto> {
    return this.tenantService.update(id, updateTenantDto);
  }

  @Put(':id/verify')
  @ApiOperation({ summary: 'Verify tenant profile' })
  @ApiResponse({ status: 200, description: 'Tenant verified successfully' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async verify(@Param('id') id: string): Promise<{ message: string }> {
    await this.tenantService.verify(id);
    return { message: 'Tenant verified successfully' };
  }

  @Put(':id/assign-property')
  @ApiOperation({ summary: 'Assign property to tenant' })
  @ApiResponse({ status: 200, description: 'Property assigned successfully' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async assignProperty(
    @Param('id') id: string,
    @Body() assignPropertyDto: { propertyId: string; caretakerId: string; leaseStartDate: Date; leaseEndDate: Date; monthlyRent: number; securityDeposit: number; leaseTerms?: string }
  ): Promise<{ message: string }> {
    await this.tenantService.assignProperty(id, assignPropertyDto);
    return { message: 'Property assigned successfully' };
  }

  @Put(':id/remove-property')
  @ApiOperation({ summary: 'Remove property assignment from tenant' })
  @ApiResponse({ status: 200, description: 'Property assignment removed successfully' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async removeProperty(@Param('id') id: string): Promise<{ message: string }> {
    await this.tenantService.removeProperty(id);
    return { message: 'Property assignment removed successfully' };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete tenant profile' })
  @ApiResponse({ status: 200, description: 'Tenant deleted successfully' })
  @ApiResponse({ status: 404, description: 'Tenant not found' })
  async remove(@Param('id') id: string): Promise<{ message: string }> {
    await this.tenantService.remove(id);
    return { message: 'Tenant deleted successfully' };
  }
}
