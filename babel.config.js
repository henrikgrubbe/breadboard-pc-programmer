module.exports = {
    presets: [
        '@vue/cli-plugin-babel/preset'
    ],
    'plugins': [
        ['prismjs', {
            'languages': ['javascript', 'armasm'],
            'plugins': ['line-numbers'],
            'theme': 'tomorrow',
            'css': true
        }]
    ]
}
