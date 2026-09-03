declare module "https://deno.land/std@0.168.0/http/server.ts" {
  export interface ConnInfo {
    readonly localAddr: { transport: "tcp"; hostname: string; port: number };
    readonly remoteAddr: { transport: "tcp"; hostname: string; port: number };
  }

  export interface ServeInit {
    port?: number;
    hostname?: string;
    signal?: AbortSignal;
    onError?: (error: unknown) => Response | Promise<Response>;
    onListen?: (params: { port: number; hostname: string }) => void;
  }

  export type Handler = (
    request: Request,
    connInfo?: ConnInfo
  ) => Response | Promise<Response>;

  export function serve(
    handler: Handler,
    init?: ServeInit
  ): Promise<void> | void;
}
