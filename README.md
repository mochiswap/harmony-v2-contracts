## Mochiswap Harmony v2

Mochiswap has been upgraded! This is a complete reboot. Even the token is being upgraded.

The token can be 1:1 swapped using and upgrade contract. On swap the old hMOCHI tokens are burned and new hMOCHI tokens are minted.
Upgrade contract:

### Addresses
Same as before:
- Mochiswap Router: 0x5F4467ccfa269BcED8F2bC4057bBF17435d11A0d
- Mochiswap Factory: 0x3bEF610a4A6736Fd00EBf9A73DA5535B413d82F6
- Original hMochi(please upgrade): 0x0dD740Db89B9fDA3Baadf7396DdAD702b6E8D6f5

New Contracts:
- hMOCHI(new): 0x691f37653f2fBed9063fEBB1A7f54BC5C40bEd8C
- xMOCHI(staked hMOCHI): 0xD3a7C43Cbe2C959B6b7eB188D328E1094a3735B0 
- Upgrade 1:1 swap: 0x50340f0D03f8c1Ff5DD1A7c9DB1e0c2684930ED1
- MOCHI Vault (Single Staking): 0x2A9BB5aCF08807B58936c83413d052F66aC31739
- MochiChef V2: 0xD0Cb3E55449646c9735D53E83EEA5Eb7e97A52Dc 

There is no deposit fee.

Early LP withdraw fees:

There is a 25% fee if you deposit and withdraw on the same block. This helps protect against flashloans.

Starting on the next block:
- Harmony Blocks = 1 day = 43200 // 2 sec // 30 per min
- fee structure for "early" LP Withdrawal
- 25% same block flash loan protection
- 5% less than 1 day
- 4% more than 1 day less than 2 days
- 3% more than 2 days less than 3 days
- 1% more than 3 days less than 7 days
- 0.5% more than 7 days less than 14 days
- 0.1% more than 14 days

This is counted from your LAST WITHDRAWAL in a particular pair and RESETS when u withdraw.

Note: Harmony Blocks = 1 day = 46800 // 2 sec // 30 per min

ChefV2 LP POOLS 

bMOCHI solo:
pid: 0
LP Address: AUTO STAKE SETUP 
alloc: 1000

hMOCHI-WONE:
pid: 1
LP: 0x890eF2508d507628A6D9a40653A1a5e57851a0aE
alloc: 5000

hMOCHI-BUSD
pid: 2
LP: 0xfFd19ed55e44F97435675Ff6Bf9aea7B6b515616

BUSD-ONE
pid: 3
LP: 0x46Ac8DdBDf4B16D6312693F8F25798db6f65Bcc1

FlokiONE-hMOCHI
pid: 4
LP: 0x3541eb38d21c5e9b68f806eb3eab7f20f20c3794

TODO: update w/additional pools