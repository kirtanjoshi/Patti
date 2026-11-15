import { PrismaClient, WalletAccountType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding house wallet accounts...');
  const houseAccountTypes: WalletAccountType[] = [
    WalletAccountType.HOUSE_RAKE,
    WalletAccountType.HOUSE_BOT,
    WalletAccountType.HOUSE_REWARDS,
    WalletAccountType.HOUSE_IAP,
  ];

  for (const type of houseAccountTypes) {
    const existing = await prisma.walletAccount.findFirst({
      where: { type },
    });

    if (!existing) {
      const created = await prisma.walletAccount.create({
        data: {
          type,
          balance: BigInt(0),
          held: BigInt(0),
        },
      });
      console.log(`Created house wallet account: ${type} (ID: ${created.id})`);
    } else {
      console.log(`House wallet account ${type} already exists.`);
    }
  }

  console.log('Seeding default RemoteConfig...');
  const defaultConfigs = [
    { key: 'minAppVersion', value: { android: '1.0.0', ios: '1.0.0' } },
    { key: 'maintenanceMode', value: { enabled: false, message: '' } },
    {
      key: 'economyTiers',
      value: {
        beginner: { entry: 100, minBalance: 1000, unlockLevel: 1 },
        bronze: { entry: 500, minBalance: 5000, unlockLevel: 3 },
        silver: { entry: 2000, minBalance: 20000, unlockLevel: 8 },
        gold: { entry: 10000, minBalance: 100000, unlockLevel: 15 },
        diamond: { entry: 50000, minBalance: 500000, unlockLevel: 25 },
      },
    },
    {
      key: 'dailyRewards',
      value: [500, 750, 1000, 1250, 1500, 2000, 3000],
    },
  ];

  for (const cfg of defaultConfigs) {
    await prisma.remoteConfig.upsert({
      where: { key: cfg.key },
      create: { key: cfg.key, value: cfg.value },
      update: { value: cfg.value },
    });
  }
  console.log('RemoteConfig seeded.');
}

main()
  .catch((e) => {
    console.error('Error during database seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
