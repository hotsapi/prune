const aws = require('aws-sdk');

const config = {};
if (process.env.DEV === 'true') {
  const endpoint = process.env.AWS_ENDPOINT;
  Object.assign(config, {endpoint, s3ForcePathStyle: true, logger: console});
}
const s3 = new aws.S3(config);

const CronJob = require('cron').CronJob;
const mysql = require('mysql2/promise');

let db;

async function deleteReplay(replay) {
	try {
//		process.stdout.write(' ');
		await s3.deleteObject({Bucket: 'hotsapi', Key: `${replay.filename}.StormReplay`}).promise();
//		process.stdout.write(',');
		await db.query('update replays set deleted = 1 where id = ? limit 1', [replay.id]);
//		process.stdout.write('.');
	} catch (err) {
//	    console.log('');
		console.log(err);
	}
}

async function main() {
    db = await mysql.createPool({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT || '3306',
        user: process.env.DB_USER || 'root',
        database: process.env.DB_DATABASE || 'hotsapi',
        password: process.env.DB_PASSWORD,
        connectionLimit: 100
    });
    while(true) {
        console.log('Getting next chunk');
        console.time('Query time');
        const [rows, _] = await db.query(`
            select id, filename from replays where processed = 1 and deleted = 0 and not (
                   game_type = 'HeroLeague' and game_date > now() - interval 90 day
                or game_type = 'TeamLeague' and game_date > now() - interval 90 day
                or game_date > now() - interval 30 day
                or created_at > now() - interval 7 day) 
            limit 30000`);
        console.timeEnd('Query time');
        console.log(`Got ${rows.length} results`);
        if (rows.length === 0) {
            console.log('Done');
            break;
        }
        console.log('Deleting...');
        await Promise.all(rows.map(r => deleteReplay(r)));
    }
}

const cronTime = process.env.CRON_TIME || '* */60 * * * *';
new CronJob({cronTime, onTick: main, runOnInit: true}).start();
