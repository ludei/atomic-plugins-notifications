#!/usr/bin/env node

var fs = require('fs');
var path = require('path');

module.exports = function(context) {
    if (context.opts.cordova.platforms.indexOf('android') <= -1)
        return;

    var manifest_xml = path.join(context.opts.projectRoot, 'platforms', 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    var et = context.requireCordovaModule('elementtree');

    var data = fs.readFileSync(manifest_xml).toString();
    var etree = et.parse(data);

    var activities = etree.findall('./application/activity');
    for (var i=0; i<activities.length; i++) {

        for (var j=0; j<activities[i].len(); j++) {
            if (activities[i].get('android:name').indexOf("com.ludei.devapplib.android.DevAppActivity") === 0)
                continue;

            var item = activities[i].getItem(j);
            if (item.tag === "intent-filter") {
                var category = item.find('category');
                if (category) {
                    var category_name = category.get('android:name');
                    if (category_name === "android.intent.category.LAUNCHER") {
                        var default_category = new et.Element();
                        default_category.tag = 'category';
                        default_category.attrib['android:name'] = 'android.intent.category.DEFAULT';
                        item.append(default_category);

                        var action = new et.Element();
                        action.tag = 'action';
                        action.attrib['android:name'] = '${applicationId}.ludei.notifications.OPEN';
                        item.append(action);
                    }
                }
            }
        }
    }

    data = etree.write({'indent': 4});
    fs.writeFileSync(manifest_xml, data);
}