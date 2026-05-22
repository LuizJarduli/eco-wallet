export type DevicePlatform = "android" | "ios" | "web";

export interface PushMessage {
  token: string;
  platform: DevicePlatform;
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface PushProvider {
  send(message: PushMessage): Promise<void>;
}

export class CompositePushProvider implements PushProvider {
  constructor(
    private readonly providers: Partial<Record<DevicePlatform, PushProvider>>
  ) {}

  async send(message: PushMessage): Promise<void> {
    const provider = this.providers[message.platform];

    if (!provider) {
      throw new Error(`No push provider configured for platform ${message.platform}.`);
    }

    await provider.send(message);
  }
}
