import type { SupabaseServiceClient } from "../../core/supabase/service-client.js";
import { createSupabaseServiceClient } from "../../core/supabase/service-client.js";
import type { DevicePlatform } from "./push-provider.js";

export interface DeviceTokenRecord {
  id: string;
  userId: string;
  platform: DevicePlatform;
  token: string;
}

export interface DeviceTokenRepository {
  listByUserId(userId: string): Promise<DeviceTokenRecord[]>;
}

interface DeviceTokenRow {
  id: string;
  user_id: string;
  platform: DevicePlatform;
  token: string;
}

const mapRow = (row: DeviceTokenRow): DeviceTokenRecord => ({
  id: row.id,
  platform: row.platform,
  token: row.token,
  userId: row.user_id
});

export class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  constructor(private readonly client: SupabaseServiceClient = createSupabaseServiceClient()) {}

  async listByUserId(userId: string): Promise<DeviceTokenRecord[]> {
    const { data, error } = await this.client
      .from("device_tokens")
      .select("id,user_id,platform,token")
      .eq("user_id", userId);

    if (error) {
      throw error;
    }

    return (data ?? []).map((row) => mapRow(row as DeviceTokenRow));
  }
}
