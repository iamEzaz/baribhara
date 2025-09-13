import { Expose } from 'class-transformer';

export class ApiResponse<T = any> {
  @Expose()
  success: boolean;

  @Expose()
  message: string;

  @Expose()
  data?: T;

  @Expose()
  errors?: string[];

  @Expose()
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    totalPages?: number;
  };

  constructor(
    success: boolean,
    message: string,
    data?: T,
    errors?: string[],
    meta?: any,
  ) {
    this.success = success;
    this.message = message;
    this.data = data;
    this.errors = errors;
    this.meta = meta;
  }

  static success<T>(data: T, message = 'Success'): ApiResponse<T> {
    return new ApiResponse(true, message, data);
  }

  static error(message: string, errors?: string[]): ApiResponse {
    return new ApiResponse(false, message, undefined, errors);
  }

  static paginated<T>(
    data: T[],
    page: number,
    limit: number,
    total: number,
    message = 'Success',
  ): ApiResponse<T[]> {
    const totalPages = Math.ceil(total / limit);
    return new ApiResponse(true, message, data, undefined, {
      page,
      limit,
      total,
      totalPages,
    });
  }
}

export class PaginationDto {
  @Expose()
  page: number = 1;

  @Expose()
  limit: number = 10;

  @Expose()
  sortBy?: string;

  @Expose()
  sortOrder: 'ASC' | 'DESC' = 'DESC';

  @Expose()
  search?: string;
}
