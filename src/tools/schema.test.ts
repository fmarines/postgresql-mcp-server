import { describe, it, expect, vi } from 'vitest';
import { manageSchemaTools } from './schema';
import { Pool } from 'pg';
import { DatabaseConnection } from '../utils/connection';

describe('manageSchemaTools', () => {
  const mockGetConnectionString = vi.fn().mockReturnValue('mock-connection-string');

  it('should handle get_info operation', async () => {
    const mockPool = {
      query: vi.fn().mockResolvedValue({ rows: [{ table_name: 'users' }] }),
      connect: vi.fn(),
      disconnect: vi.fn(),
    } as unknown as any; // Broaden mock for DatabaseConnection
    vi.spyOn(DatabaseConnection, 'getInstance').mockReturnValue(mockPool);

    const result = await manageSchemaTools.execute({
      operation: 'get_info'
    }, mockGetConnectionString);

    expect(result.content).toContainEqual(expect.objectContaining({ type: 'text' }));
    expect(mockPool.query).toHaveBeenCalled();
  });

  it('should throw error for invalid operation', async () => {
    await expect(manageSchemaTools.execute({ operation: 'invalid' }, mockGetConnectionString)).rejects.toThrow();
  });
}); 