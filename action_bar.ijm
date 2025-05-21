<fromString>
<stickToImageJ>
<noGrid>
<line>

<text><html><font color='black'><b> Custom Macro Bar

<button>
label=<html><font color='black'><b> Cell Counting
bgcolor=#ffae00
arg=cellCounting();
<separator>

<button>
label=<html><font color='black'><b> Image Crop
bgcolor=#b48aff
arg=imageCrop();
<separator>
 
<button>
label=<html><font color='black'><b> Color Conversion and Save
bgcolor=#60c1ff
arg=colorConversionAndSave();
<separator>

<button>
label=<html><font color='black'><b> Split Channel
bgcolor=#ffd03e
arg=splitChannel();
<separator>

<button>
label=<html><font color='black'><b> Stack Color
bgcolor=#b4e297
arg=stackColor();
<separator>

<button>
label=<html><font color='black'><b> Only Merge
bgcolor=#ffae00
arg=onlyMerge();
<separator>

<button>
label=<html><font color='black'><b> Merge Channel
bgcolor=#b48aff
arg=mergeChannel();
<separator>

<button>
label=<html><font color='black'><b> conversion HotColor
bgcolor=#e77471
arg=conversionHotColor();
<separator>

<button>
label=<html><font color='black'><b> X
bgcolor=#ff989c
arg=close();

</line>

<codeLibrary>

// Cell Counting 함수 정의
function cellCounting() {
    inputDir = getDirectory('Choose a directory containing images for vertex counting');
    if (inputDir == '') {
        exit('You must select a directory.');
    }

    csvPath = inputDir + 'vertex_count_results.csv';
    File.open(csvPath);
    File.append('Filename,Vertex Count\n', csvPath);

    processedDir = inputDir + 'processed/';
    if (!File.exists(processedDir)) {
        File.makeDirectory(processedDir);
    }

    fileList = getFileList(inputDir);
    Array.sort(fileList);

    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], '.tif') || endsWith(fileList[i], '.jpg') || endsWith(fileList[i], '.png')) {
            open(inputDir + fileList[i]);
            run('8-bit');
            run('Median...', 'radius=1');
            setThreshold(11, 255);
            setOption('BlackBackground', false);
            run('Convert to Mask');
            run('Watershed');
            run('Analyze Particles...', 'size=5-Infinity circularity=0.2-1.0 show=Nothing display exclude clear include summarize add');
            vertexCount = nResults;
            File.append(fileList[i] + ',' + vertexCount + '\n', csvPath);
            savePath = processedDir + replaceSpaces(replaceExtension(fileList[i], '_processed.jpg'));
            saveAs('Jpeg', savePath);
            run('Close All');
            run('Clear Results');
        }
    }

    print('Vertex counting complete. Results saved to: ' + csvPath);
}

function replaceExtension(filename, newExtension) {
    dotIndex = lastIndexOf(filename, ".");
    if (dotIndex != -1) {
        return substring(filename, 0, dotIndex) + "." + newExtension;
    } else {
        return filename + "." + newExtension;
    }
}

function replaceSpaces(filename) {
    return replace(replace(filename, " ", "_"), ",", "_");
}

// Image Crop 함수 정의
function imageCrop() {
    outputDir = getDirectory('Choose a Directory to Save Cropped Images');
    firstImageID = getImageID();
    firstImageTitle = getTitle();
    run('Duplicate...', 'title=firstImageDuplicate');
    selectWindow(firstImageTitle);
    roiManager('Add');
    roiManager('Select', 0);
    getSelectionBounds(x, y, width, height);
    makeRectangle(x, y, width, height);
    run('Line Width...', 'line=5');
    setColor('white');
    run('Draw');

    if (endsWith(firstImageTitle, '.tif')) {
        savePath = outputDir + replace(firstImageTitle, '.tif', '_Crop_original.jpg');
    } else if (endsWith(firstImageTitle, '.jpg')) {
        savePath = outputDir + replace(firstImageTitle, '.jpg', '_Crop_original.jpg');
    }
    saveAs('Jpeg', savePath);
    close();

    selectWindow('firstImageDuplicate');
    makeRectangle(x, y, width, height);
    run('Crop');

    if (endsWith(firstImageTitle, '.tif')) {
        savePath = outputDir + replace(firstImageTitle, '.tif', '_crop.jpg');
    } else if (endsWith(firstImageTitle, '.jpg')) {
        savePath = outputDir + replace(firstImageTitle, '.jpg', '_crop.jpg');
    }
    saveAs('Jpeg', savePath);
    close();

    imageTitles = newArray(nImages());
    for (i = 1; i <= nImages(); i++) {
        selectImage(i);
        imageTitles[i-1] = getTitle();
    }

    for (i = 0; i < imageTitles.length; i++) {
        selectWindow(imageTitles[i]);
        currentImage = getTitle();

        if (currentImage != firstImageTitle) {
            makeRectangle(x, y, width, height);
            run('Crop');

            if (endsWith(currentImage, '.tif')) {
                savePath = outputDir + replace(currentImage, '.tif', '_crop.jpg');
            } else if (endsWith(currentImage, '.jpg')) {
                savePath = outputDir + replace(currentImage, '.jpg', '_crop.jpg');
            }

            saveAs('Jpeg', savePath);
            close();
        }
    }

    roiManager('Deselect');
    roiManager('Delete');
}

// Color Conversion and Save 함수 정의
function colorConversionAndSave() {
    inputDir = getDirectory('Choose a Directory');
    if (inputDir == '') exit('No directory selected.');

    outputDir = inputDir + 'conversion\\';
    File.makeDirectory(outputDir);

    while (nImages > 0) {
        close();
    }

    fileList = getFileList(inputDir);

    if (fileList.length == 0) {
        exit('No images found in the selected directory.');
    }

    for (i = 0; i < fileList.length; i++) {
        filePath = inputDir + fileList[i];
        
        // 파일 경로를 출력하여 디버깅
        print("Attempting to open file: " + filePath);
        
        open(filePath);

        // 이미지가 제대로 열렸는지 확인
        if (nImages == 0) {
            print("Failed to open image: " + filePath);
            continue;
        }

        noiceLUTs();

        title = getTitle();
        dotIndex = lastIndexOf(title, '.');
        if (dotIndex != -1) {
            title = substring(title, 0, dotIndex);
        }
        savePath = outputDir + title + '_conversion.jpg';

        saveAs('Jpeg', savePath);
        close();
    }

    showMessage('Processing Complete', 'All images have been processed and saved in the conversion folder.');
}

function LUTmaker(r, g, b) {
    R = newArray(256);
    G = newArray(256);
    B = newArray(256);
    for (i = 0; i < 256; i++) { 
        R[i] = (r / 256) * (i + 1);
        G[i] = (g / 256) * (i + 1);
        B[i] = (b / 256) * (i + 1);
    }
    setLut(R, G, B);
}

function noiceLUTs() {
    if (nImages == 0) exit('no image');
    if (isKeyDown('shift') && bitDepth() != 24) {
        getDimensions(width, height, channels, slices, frames);
        if (channels == 2) {
            Stack.setChannel(1); LUTmaker(255, 100, 0); // orange
            Stack.setChannel(2); LUTmaker(0, 155, 255); // blue
        }
        if (channels == 3) {
            Stack.setChannel(1); LUTmaker(255, 0, 255); // Magenta
            Stack.setChannel(2); LUTmaker(255, 255, 0); // Yellow
            Stack.setChannel(3); LUTmaker(0, 255, 255); // Cyan
        }
    } else {
        RGBtoMYC();
    }
}

function RGBtoMYC() {
    showStatus('RGB to MYC');
    setBatchMode(true);
    if (bitDepth() == 24) { // if RGB
        getDimensions(width, height, channels, slices, frames);
        if (selectionType() != -1) {
            getSelectionBounds(x, y, width, height);
            makeRectangle(x, y, width, height);
        }
        run('Make Composite');
        run('Remove Slice Labels');
        Stack.setChannel(1); LUTmaker(255, 0, 255); // Magenta
        Stack.setChannel(2); LUTmaker(255, 255, 0); // Yellow
        Stack.setChannel(3); LUTmaker(0, 255, 255); // Cyan
        if (slices * frames == 1) {
            Stack.setDisplayMode('color');
            Stack.setDisplayMode('composite');
            run('Stack to RGB');
        }
    } else {
        Stack.setChannel(1); LUTmaker(255, 0, 255); // Magenta
        Stack.setChannel(2); LUTmaker(255, 255, 0); // Yellow
        Stack.setChannel(3); LUTmaker(0, 255, 255); // Cyan
    }
    setOption('Changes', false);
    setBatchMode(false);
}


// Conversion Hot Color 함수 정의
function conversionHotColor() {
    inputDir = getDirectory('Choose a Directory');
    if (inputDir == '') exit('No directory selected.');

    outputDir = inputDir + 'hot_conversion\\';
    File.makeDirectory(outputDir);

    while (nImages > 0) {
        close();
    }

    fileList = getFileList(inputDir);

    if (fileList.length == 0) {
        exit('No images found in the selected directory.');
    }

    for (i = 0; i < fileList.length; i++) {
        filePath = inputDir + fileList[i];
        
        // 파일 경로를 출력하여 디버깅
        print("Attempting to open file: " + filePath);
        
        open(filePath);

        // 이미지가 제대로 열렸는지 확인
        if (nImages == 0) {
            print("Failed to open image: " + filePath);
            continue;
        }

        applyHotLUTs();

        title = getTitle();
        dotIndex = lastIndexOf(title, '.');
        if (dotIndex != -1) {
            title = substring(title, 0, dotIndex);
        }
        savePath = outputDir + title + '_hot_conversion.jpg';

        saveAs('Jpeg', savePath);
        close();
    }

    showMessage('HOT Color Conversion Complete', 'All images have been processed and saved in the hot_conversion folder.');
}

// HOT LUT 적용 함수 정의
function applyHotLUTs() {
    if (nImages == 0) exit("no image");
    
    if (bitDepth() != 24) {
        getDimensions(width, height, channels, slices, frames);
        if (channels == 2) {
            Stack.setChannel(1); run("Magenta Hot");
            Stack.setChannel(2); run("Cyan Hot");
        }
        if (channels == 3) {
            Stack.setChannel(1); run("Magenta Hot");
            Stack.setChannel(2); run("Yellow Hot");
            Stack.setChannel(3); run("Cyan Hot");
        }
    } else {
        RGBtoHotMYC();
    }
}

// RGB to Hot MYC 변환 함수 정의
function RGBtoHotMYC() {
    showStatus('RGB to Hot MYC');
    setBatchMode(true);
    
    if (bitDepth() == 24) { // if RGB
        getDimensions(width, height, channels, slices, frames);
        if (selectionType() != -1) {
            getSelectionBounds(x, y, width, height);
            makeRectangle(x, y, width, height);
        }
        run('Make Composite');
        run('Remove Slice Labels');
        Stack.setChannel(1); run("Magenta Hot");
        Stack.setChannel(2); run("Yellow Hot");
        Stack.setChannel(3); run("Cyan Hot");
        if (slices * frames == 1) {
            Stack.setDisplayMode('color');
            Stack.setDisplayMode('composite');
            run('Stack to RGB');
        }
    } else {
        Stack.setChannel(1); run("Magenta Hot");
        Stack.setChannel(2); run("Yellow Hot");
        Stack.setChannel(3); run("Cyan Hot");
    }
    setOption('Changes', false);
    setBatchMode(false);
}




// Split Channel for multiple images in a folder
function splitChannelBatch() {
    folder = getDirectory("Choose a folder with image files");
    if (folder == null) {
        exit("No folder selected.");
    }

    fileList = getFileList(folder);

    for (i = 0; i < fileList.length; i++) {
        file = fileList[i];
        if (!(endsWith(file, ".jpg") || endsWith(file, ".tif") || endsWith(file, ".tiff") || endsWith(file, ".png"))) {
            continue; // Skip non-image files
        }

        fullPath = folder + file;
        fileName = getFileNameWithoutExtension(fullPath);
        outputDir = folder + fileName + File.separator;

        if (!File.exists(outputDir)) {
            success = File.makeDirectory(outputDir);
            if (!success) {
                waitForDirectory(outputDir);
            }
        }

        open(fullPath);

        // Convert tif to jpg
        if (endsWith(file, ".tif") || endsWith(file, ".tiff")) {
            originalSavePath = outputDir + fileName + '.jpg';
            saveAs('Jpeg', originalSavePath);
            close();
            open(originalSavePath);
        } else {
            originalSavePath = outputDir + fileName + '_original.jpg';
            saveAs('Jpeg', originalSavePath);
        }

        imageType = getInfo('image.type');
        if (imageType != 'composite') {
            run('Make Composite', 'display=Composite');
        }

        run('Split Channels');
        saveChannel('C1-' + fileName + '.jpg', outputDir + fileName + '_R.jpg');
        saveChannel('C2-' + fileName + '.jpg', outputDir + fileName + '_G.jpg');
        saveChannel('C3-' + fileName + '.jpg', outputDir + fileName + '_B.jpg');
        run('Close All');

        // R+G
        open(outputDir + fileName + '_R.jpg');
        run('RGB Color');
        rename('C1-' + fileName + '.jpg');

        open(outputDir + fileName + '_G.jpg');
        run('RGB Color');
        rename('C2-' + fileName + '.jpg');

        run('Merge Channels...', 'c1=[C1-' + fileName + '.jpg] c2=[C2-' + fileName + '.jpg] create');
        saveAs('Jpeg', outputDir + fileName + '_R+G.jpg');
        run('Close All');

        // R+B
        open(outputDir + fileName + '_R.jpg');
        run('RGB Color');
        rename('C1-' + fileName + '.jpg');

        open(outputDir + fileName + '_B.jpg');
        run('RGB Color');
        rename('C3-' + fileName + '.jpg');

        run('Merge Channels...', 'c1=[C1-' + fileName + '.jpg] c3=[C3-' + fileName + '.jpg] create');
        saveAs('Jpeg', outputDir + fileName + '_R+B.jpg');
        run('Close All');

        // G+B
        open(outputDir + fileName + '_G.jpg');
        run('RGB Color');
        rename('C2-' + fileName + '.jpg');

        open(outputDir + fileName + '_B.jpg');
        run('RGB Color');
        rename('C3-' + fileName + '.jpg');

        run('Merge Channels...', 'c2=[C2-' + fileName + '.jpg] c3=[C3-' + fileName + '.jpg] create');
        saveAs('Jpeg', outputDir + fileName + '_G+B.jpg');
        run('Close All');
    }
}

// Helper functions
function getFileNameWithoutExtension(path) {
    name = File.nameWithoutExtension(path);
    return name;
}

function waitForDirectory(dir) {
    while (!File.exists(dir)) {
        wait(100);
    }
}

function saveChannel(windowTitle, savePath) {
    selectWindow(windowTitle);
    saveAs('Jpeg', savePath);
    close();
}

splitChannelBatch();



function waitForDirectory(path) {
    attempts = 0;
    while (!File.exists(path) && attempts < 10) {
        wait(100);
        attempts++;
    }
    if (!File.exists(path)) {
        exit('Failed to create directory after multiple attempts: ' + path);
    }
}

function getParent(path) {
    return substring(path, 0, lastIndexOf(path, File.separator));
}

function getFileNameWithoutExtension(path) {
    name = substring(path, lastIndexOf(path, File.separator) + 1);
    return substring(name, 0, lastIndexOf(name, '.'));
}

function saveChannel(windowTitle, savePath) {
    selectWindow(windowTitle);
    run('RGB Color');
    saveAs('Jpeg', savePath);
    close();
}

// Stack Color 함수 정의
function stackColor() {
    colors = newArray('Red', 'Green', 'Blue', 'Cyan', 'Magenta', 'Yellow', 'Grays');
    numFolders = getNumber('Enter the number of folders (1-4)', 2);

    if (numFolders < 1 || numFolders > 4) {
        exit('Invalid number of folders. Please enter a number between 1 and 4.');
    }

    dirs = newArray(numFolders);
    colorsSelected = newArray(numFolders);
    outputDirs = newArray(numFolders);

    for (i = 0; i < numFolders; i++) {
        dirs[i] = getDirectory('Choose folder ' + (i + 1));
        if (dirs[i] != '') {
            colorsSelected[i] = chooseColor(i + 1, colors);
            outputDirs[i] = dirs[i] + 'LUT_' + colorsSelected[i] + '_' + getFolderName(dirs[i]) + '/';
            createDirectory(outputDirs[i]);
        } else {
            exit('You must select a folder for each folder.');
        }
    }

    for (i = 0; i < numFolders; i++) {
        processFolder(dirs[i], colorsSelected[i], outputDirs[i]);
    }
}

function chooseColor(folderNumber, colors) {
    Dialog.create('Choose LUT color for folder ' + folderNumber);
    Dialog.addChoice('Color:', colors);
    Dialog.show();
    return Dialog.getChoice();
}

function createDirectory(path) {
    if (!File.exists(path)) {
        success = File.makeDirectory(path);
        if (!success) {
            waitForDirectory(path);
        }
    }
}

function waitForDirectory(path) {
    attempts = 0;
    while (!File.exists(path) && attempts < 10) {
        wait(100);
        attempts++;
    }
    if (!File.exists(path)) {
        exit('Failed to create directory after multiple attempts: ' + path);
    }
}

function processFolder(folder, color, outputDir) {
    if (File.exists(outputDir)) {
        list = getFileList(folder);
        for (i = 0; i < list.length; i++) {
            if (endsWith(list[i], '.tif') || endsWith(list[i], '.tiff')) {
                processFile(folder + list[i], color, outputDir);
            }
        }
    } else {
        exit('Failed to access directory: ' + outputDir);
    }
}

function processFile(filepath, color, outputDir) {
    open(filepath);
    setColorLUT(color);
    run('Apply LUT', 'stack');
    baseName = removeExtension(getTitle());
    saveStackSlicesAsJpeg(baseName, outputDir);
    close();
}

function setColorLUT(color) {
    if (color == 'Red') {
        run('Red', 'stack');
    } else if (color == 'Green') {
        run('Green', 'stack');
    } else if (color == 'Blue') {
        run('Blue', 'stack');
    } else if (color == 'Cyan') {
        run('Cyan', 'stack');
    } else if (color == 'Magenta') {
        run('Magenta', 'stack');
    } else if (color == 'Yellow') {
        run('Yellow', 'stack');
    } else if (color == 'Grays') {
        run('Grays', 'stack');
    }
}

function saveStackSlicesAsJpeg(baseName, outputDir) {
    slices = nSlices();
    labels = getMetadata('Label');
    labelList = newArray(slices);
    if (labels != '') {
        labelList = split(labels, '\\n');
    }
    for (j = 1; j <= slices; j++) {
        setSlice(j);
        run('RGB Color');
        if (labels != '' && j <= lengthOf(labelList)) {
            sliceName = removeExtension(labelList[j - 1]);
        } else {
            sliceName = 'Pos00' + j;
        }
        savePath = outputDir + replaceSpaces(baseName + '_' + sliceName + '.jpg');
        saveAs('Jpeg', savePath);
    }
}

function getFolderName(path) {
    parts = split(path, '\\\\');
    return parts[lengthOf(parts) - 1];
}

function removeExtension(filename) {
    dotIndex = lastIndexOf(filename, '.');
    if (dotIndex != -1) {
        return substring(filename, 0, dotIndex);
    } else {
        return filename;
    }
}

// Only Merge 함수 정의
function onlyMerge() {
    colors = newArray("Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "Grays");
    channels = newArray("c1", "c2", "c3", "c5", "c6", "c7", "c4");

    numFolders = getNumber("Enter the number of folders (2-4)", 2);
    if (numFolders < 2 || numFolders > 4) {
        exit("Invalid number of folders. Please enter a number between 2 and 4.");
    }

    outputDirs = newArray(numFolders);
    channelsSelected = newArray(numFolders);

    for (i = 0; i < numFolders; i++) {
        outputDirs[i] = getDirectory("Choose folder " + (i + 1) + " containing LUT colored images");
        if (outputDirs[i] == "") {
            exit("You must select a folder for each folder.");
        } else {
            channel = getChannelFromFolderName(outputDirs[i]);
            if (channel == "") {
                exit("Folder name must contain one of the LUT colors: Red, Green, Blue, Cyan, Magenta, Yellow, Grays.");
            }
            channelsSelected[i] = channel;
            print("Selected folder " + (i + 1) + ": " + outputDirs[i] + " assigned to channel " + channel);
        }
    }

    mergeOutputDir = getDirectory("Choose the output directory for merged images");
    if (mergeOutputDir == "") {
        exit("You must select an output directory for merged images.");
    } else {
        print("Selected merge output directory: " + mergeOutputDir);
    }

    mergeImages(outputDirs, mergeOutputDir, numFolders, channelsSelected);
}

function getChannelFromFolderName(folderName) {
    folderName = toLowerCase(folderName);
    for (i = 0; i < colors.length; i++) {
        if (indexOf(folderName, toLowerCase(colors[i])) != -1) {
            return channels[i];
        }
    }
    return "";
}

function mergeImages(outputDirs, mergeOutputDir, numFolders, channelsSelected) {
    list = getFileList(outputDirs[0]);
    numImages = list.length;
    for (i = 0; i < numImages; i++) {
        openImages = newArray(numFolders);
        for (j = 0; j < outputDirs.length; j++) {
            imgList = getFileList(outputDirs[j]);

            // Sort file names in each directory
            Array.sort(imgList);

            if (i < imgList.length && endsWith(imgList[i], ".jpg")) {
                open(outputDirs[j] + "\\" + imgList[i]);
                openImages[j] = getTitle();
            } else {
                exit("There must be an image from each folder to merge.");
            }
        }

        // Ensure all images are in RGB format before merging
        for (k = 0; k < openImages.length; k++) {
            selectWindow(openImages[k]);
            run("RGB Color");
        }

        // Merge channels without changing colors
        mergeCommand = "";
        for (k = 0; k < numFolders; k++) {
            mergeCommand += channelsSelected[k] + "=" + openImages[k] + " ";
        }
        mergeCommand += "create keep";

        run("Merge Channels...", mergeCommand);

        // Use the name of the first image as the base name
        baseName = openImages[0].substring(0, openImages[0].lastIndexOf('.'));

        // Save the merged image as JPEG with the original file name + "_merge"
        saveMergedPath = mergeOutputDir + "\\" + replaceSpaces(baseName) + "_merge.jpg";
        saveAs("Jpeg", saveMergedPath);
        closeAllImages();
    }
}



// Merge Channel 함수 정의
function mergeChannel() {
    colors = newArray("Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "Grays");
    channels = newArray("c1", "c2", "c3", "c5", "c6", "c7", "c4");

    numFolders = getNumber("Enter the number of folders (1-4)", 2);
    if (numFolders < 1 || numFolders > 4) {
        exit("Invalid number of folders. Please enter a number between 1 and 4.");
    }

    dirs = newArray(numFolders);
    colorsSelected = newArray(numFolders);
    channelsSelected = newArray(numFolders);
    outputDirs = newArray(numFolders);

    for (i = 0; i < numFolders; i++) {
        dirs[i] = getDirectory("Choose folder " + (i + 1));
        if (dirs[i] != "") {
            colorsSelected[i] = chooseColor(i + 1, colors);
            channelsSelected[i] = getChannel(colorsSelected[i]);
            outputDirs[i] = dirs[i] + "LUT_" + colorsSelected[i] + "_" + getFolderName(dirs[i]) + "/";
            createDirectory(outputDirs[i]);
        } else {
            exit("You must select a folder for each folder.");
        }
    }

    mergeOutputDir = getDirectory("Choose the output directory for merged images");
    if (mergeOutputDir == "") {
        exit("You must select an output directory for merged images.");
    }

    for (i = 0; i < numFolders; i++) {
        processFolder(dirs[i], colorsSelected[i], outputDirs[i]);
    }

    mergeImages(outputDirs, mergeOutputDir, numFolders, channelsSelected);
}

function chooseColor(folderNumber, colors) {
    Dialog.create("Choose LUT color for folder " + folderNumber);
    Dialog.addChoice("Color:", colors);
    Dialog.show();
    return Dialog.getChoice();
}

function getChannel(color) {
    index = arrayIndexOf(colors, color);
    return channels[index];
}

function arrayIndexOf(array, value) {
    for (i = 0; i < array.length; i++) {
        if (array[i] == value) {
            return i;
        }
    }
    return -1; // Value not found
}

function createDirectory(path) {
    if (!File.exists(path)) {
        success = File.makeDirectory(path);
        if (!success) {
            waitForDirectory(path);
        }
    }
}

function waitForDirectory(path) {
    attempts = 0;
    while (!File.exists(path) && attempts < 10) {
        wait(100);
        attempts++;
    }
    if (!File.exists(path)) {
        exit("Failed to create directory after multiple attempts: " + path);
    }
}

function processFolder(folder, color, outputDir) {
    // Ensure the directory was created successfully before proceeding
    if (File.exists(outputDir)) {
        list = getFileList(folder);
        for (i = 0; i < list.length; i++) {
            // .tif, .tiff, .jpg 확장자만 처리
            if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".jpg")) {
                open(folder + list[i]);
                setColorLUT(color);
                
                // Apply existing brightness/contrast settings
                run("Apply LUT");
                
                // Convert to RGB
                run("RGB Color");

                // Save as JPEG with spaces replaced by underscores
                savePath = outputDir + replaceSpaces(replaceExtension(list[i], "jpg"));
                saveAs("Jpeg", savePath);
                close();
            }
        }
    } else {
        exit("Failed to access directory: " + outputDir);
    }
}

function closeAllImages() {
    while (nImages() > 0) {
        selectImage(nImages());
        close();
    }
}

function setColorLUT(color) {
    if (color == "Red") {
        run("Red");
    } else if (color == "Green") {
        run("Green");
    } else if (color == "Blue") {
        run("Blue");
    } else if (color == "Cyan") {
        run("Cyan");
    } else if (color == "Magenta") {
        run("Magenta");
    } else if (color == "Yellow") {
        run("Yellow");
    } else if (color == "Grays") {
        run("Grays");
    }
}

function getFolderName(path) {
    // Extract the folder name from the path
    parts = split(path, "\\");
    return parts[lengthOf(parts) - 1];
}

function replaceExtension(filename, newExtension) {
    dotIndex = lastIndexOf(filename, ".");
    if (dotIndex != -1) {
        return substring(filename, 0, dotIndex) + "." + newExtension;
    } else {
        return filename + "." + newExtension;
    }
}

function replaceSpaces(filename) {
    return replace(replace(filename, " ", "_"), ",", "_");
}


</codeLibrary>
