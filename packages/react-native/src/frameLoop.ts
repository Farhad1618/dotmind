export interface FrameClient {
  readonly animating: boolean;
  tick(dt: number): void;
  setForeground(foreground: boolean): void;
}

export interface FrameScheduler {
  request(callback: (now: number) => void): number;
  cancel(handle: number): void;
}

const MAX_STEP = 0.05;

export class FrameLoop {
  private readonly scheduler: FrameScheduler;
  private readonly clients: FrameClient[] = [];
  private handle: number | null = null;
  private last = 0;
  private active = true;

  constructor(scheduler: FrameScheduler) {
    this.scheduler = scheduler;
  }

  get running(): boolean {
    return this.handle !== null;
  }

  get size(): number {
    return this.clients.length;
  }

  add(client: FrameClient): () => void {
    if (!this.clients.includes(client)) this.clients.push(client);
    client.setForeground(this.active);
    this.wake();
    return () => this.remove(client);
  }

  remove(client: FrameClient): void {
    const index = this.clients.indexOf(client);
    if (index >= 0) this.clients.splice(index, 1);
    if (!this.clients.length) this.halt();
  }

  setActive(active: boolean): void {
    if (active === this.active) return;
    this.active = active;
    for (let i = 0; i < this.clients.length; i++) this.clients[i].setForeground(active);
    if (active) this.wake();
    else this.halt();
  }

  wake(): void {
    if (this.handle !== null || !this.active || !this.anyAnimating()) return;
    this.last = 0;
    this.handle = this.scheduler.request(this.frame);
  }

  private halt(): void {
    if (this.handle !== null) this.scheduler.cancel(this.handle);
    this.handle = null;
    this.last = 0;
  }

  private anyAnimating(): boolean {
    for (let i = 0; i < this.clients.length; i++) if (this.clients[i].animating) return true;
    return false;
  }

  private readonly frame = (now: number): void => {
    this.handle = null;
    const dt = this.last ? Math.min(MAX_STEP, (now - this.last) / 1000) : 0;
    this.last = now;
    let animating = false;
    for (let i = 0; i < this.clients.length; i++) {
      const client = this.clients[i];
      if (!client.animating) continue;
      animating = true;
      client.tick(dt);
    }
    if (animating && this.active) this.handle = this.scheduler.request(this.frame);
    else this.last = 0;
  };
}
