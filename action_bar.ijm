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
label=<html><font color='black'><b> Colorblind
bgcolor=#60c1ff
arg=colorblind();
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
label=<html><font color='black'><b> X 
bgcolor=#ff989c
arg=<close>

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
    File.append('Filename,Vertex Count\\n', csvPath);

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
            File.append(fileList[i] + ',' + vertexCount + '\\n', csvPath);
            savePath = processedDir + replaceSpaces(replaceExtension(fileList[i], '_processed.jpg'));
            saveAs('Jpeg', savePath);
            run('Close All');
            run('Clear Results');
        }
    }

    print('Vertex counting complete. Results saved to: ' + csvPath);
}

function replaceExtension(filename, newExtension) {
    dotIndex = lastIndexOf(filename, '.');
    if (dotIndex != -1) {
        return substring(filename, 0, dotIndex) + newExtension;
    } else {
        return filename + newExtension;
    }
}

function replaceSpaces(filename) {
    return replace(replace(filename, ' ', '_'), ',', '_');
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

// Colorblind 함수 정의
function colorblind() {
    inputDir = getDirectory('Choose a Directory');
    if (inputDir == '') exit('No directory selected.');

    outputDir = inputDir + 'conversion\\';
    File.makeDirectory(outputDir);

    while (nImages > 0) {
        close();
    }

    fileList = getFileList(inputDir);

    for (i = 0; i < fileList.length; i++) {
        filePath = inputDir + fileList[i];
        open(filePath);
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

// Split Channel 함수 정의
function splitChannel() {
    inputFile = File.openDialog('Select an image file');

    if (inputFile == '') {
        exit('No file selected.');
    }

    filePath = inputFile;
    fileDir = getParent(filePath);
    fileName = getFileNameWithoutExtension(filePath);
    outputDir = fileDir + File.separator + fileName + File.separator;
    
    if (!File.exists(outputDir)) {
        success = File.makeDirectory(outputDir);
        if (!success) {
            waitForDirectory(outputDir);
        }
    }

    open(filePath);
    originalSavePath = outputDir + fileName + '_original.jpg';
    saveAs('Jpeg', originalSavePath);

    imageType = getInfo('image.type');
    if (imageType != 'composite') {
        run('Make Composite', 'display=Composite');
    }

    run('Split Channels');
    saveChannel('C1-' + fileName + '.jpg', outputDir + fileName + '_R.jpg');
    saveChannel('C2-' + fileName + '.jpg', outputDir + fileName + '_G.jpg');
    saveChannel('C3-' + fileName + '.jpg', outputDir + fileName + '_B.jpg');
    run('Close All');

    open(outputDir + fileName + '_R.jpg');
    run('RGB Color');
    rename('C1-' + fileName + '.jpg');
    open(outputDir + fileName + '_G.jpg');
    run('RGB Color');
    rename('C2-' + fileName + '.jpg');
    open(outputDir + fileName + '_B.jpg');
    run('RGB Color');
    rename('C3-' + fileName + '.jpg');

    run('Merge Channels...', 'c1=[C1-' + fileName + '.jpg] c2=[C2-' + fileName + '.jpg] create');
    saveAs('Jpeg', outputDir + fileName + '_R+G.jpg');
    run('Close All');

    open(outputDir + fileName + '_R.jpg');
    run('RGB Color');
    rename('C1-' + fileName + '.jpg');
    open(outputDir + fileName + '_B.jpg');
    run('RGB Color');
    rename('C3-' + fileName + '.jpg');

    run('Merge Channels...', 'c1=[C1-' + fileName + '.jpg] c3=[C3-' + fileName + '.jpg] create');
    saveAs('Jpeg', outputDir + fileName + '_R+B.jpg');
    run('Close All');

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
        savePath = outputDir + baseName + '_' + sliceName + '.jpg';
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

</codeLibrary>
