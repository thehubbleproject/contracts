// import * as mcl from "./mcl";

const amountLen = 4;
const senderLen = 4;
const receiverLen = 4;
const sigLen = 64;

export function serialize(txs: Tx[]) {
    return "0x" + txs.map(tx => tx.encode()).join("");
}

export class Tx {
    public static rand(): Tx {
        const sender = web3.utils.hexToNumber(web3.utils.randomHex(senderLen));
        const receiver = web3.utils.hexToNumber(
            web3.utils.randomHex(receiverLen)
        );
        const amount = web3.utils.hexToNumber(web3.utils.randomHex(amountLen));
        const signature = web3.utils.randomHex(sigLen);
        return new Tx(sender, receiver, amount, signature);
    }
    constructor(
        readonly sender: number,
        readonly receiver: number,
        readonly amount: number,
        readonly signature: string
    ) {}

    public hash(): string {
        return web3.utils.soliditySha3(
            { v: this.sender, t: "uint32" },
            { v: this.receiver, t: "uint32" },
            { v: this.amount, t: "uint32" }
        );
    }

    // public mapToPoint() {
    //   const e = this.hash();
    //   return mcl.g1ToHex(mcl.mapToPoint(e));
    // }

    public encode(): string {
        let sender = web3.utils.padLeft(
            web3.utils.toHex(this.sender),
            senderLen * 2
        );
        let receiver = web3.utils.padLeft(
            web3.utils.toHex(this.receiver),
            receiverLen * 2
        );
        let amount = web3.utils.padLeft(
            web3.utils.toHex(this.amount),
            amountLen * 2
        );
        return (
            sender.slice(2) +
            receiver.slice(2) +
            amount.slice(2) +
            this.signature.slice(2)
        );
    }
}
