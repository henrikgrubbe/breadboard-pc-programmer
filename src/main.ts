import {createApp} from 'vue'
import * as Sentry from '@sentry/vue';
import App from '@/App.vue';
import {BrowserTracing} from '@sentry/tracing';

const app = createApp(App);

const options = {
    dsn: 'https://bd84d092c35549a28d0470b3be99868b@o1249239.ingest.sentry.io/6409646',
    tracesSampleRate: 1.0,
    integrations: [new BrowserTracing],
};

const release = process.env.VUE_APP_SENTRY_RELEASE;
if (release === 'dev') {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    options['release'] = 'dev';
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    options['environment'] = 'dev';
}

if (release !== undefined) {
    Sentry.init(options);
}

app.mount('#app')
