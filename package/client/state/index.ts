import { cache } from "../cache";

interface StatebagPayload {
  target: { entity: number } | { player: number },
  bagname: string;
  value: any;
}

export const state = {
  set(payload: StatebagPayload) {
    const hasTarget = 'player' in payload.target || 'entity' in payload.target;

    if (!hasTarget) {
      console.error('^1payload for lib.state.set was invalid!');
      return;
    }

    emitNet('ox_lib:setstate', payload);
  },
  setPlayer(bagname: string, value: any) {
    this.set({
      target: {
        player: cache.serverId,
      },
      bagname,
      value,
    })
  },
  setEntity(entityId: number, bagname: string, value: any) {
    this.set({
      target: {
        entity: entityId,
      },
      bagname,
      value,
    })
  },
}
