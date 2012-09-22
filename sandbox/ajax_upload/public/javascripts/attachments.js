/* Redmine - project management software
   Copyright (C) 2006-2012  Jean-Philippe Lang */

var fileFieldCount = 0;

function addFile(file, eagerUpload) {

  function onLoadstart(e) {
    addFile.uploading++;
    $('input:submit:enabled', $(this).parents('form')).attr('disabled', 'disabled');    
  }

  function onProgress(e) {
    if(e.lengthComputable) {
      this.progressbar( 'value', e.loaded * 100 / e.total );
    }
  }

  if (fileFieldCount < 10 && checkFileSize(file)) {

    fileFieldCount++;

    var attachment_id = addFile.nextAttachmentId++;

    var fileSpan = $(
      '<span id="attachments[' + attachment_id + ']"> \
        <input class="readonly" type="text" name="attachments[' + attachment_id + '][filename]" readonly="readonly"></input> \
        <input type="text" class="description" name="attachments[' + attachment_id + '][description]" maxlength="255" placeholder="' + ATTACHMENT_CONFIG['HL_DESCRIPTION_PLACEHOLDER'] + '"></input> \
        <a href="#" onclick="removeFile(this); return false;"><img src="' + ATTACHMENT_CONFIG['H_DELETE_IMAGE_PATH'] + '" alt="' + ATTACHMENT_CONFIG['HL_DELETE_TITLE'] + '"></img></a> \
      </span>'
    );

    $('input[name=attachments\\[' + attachment_id + '\\]\\[filename\\]]', fileSpan).val(file.name);
    fileSpan.appendTo('#attachments_fields');

    if(eagerUpload) {
      var progressSpan = $('<div/>').insertBefore($('input[name=attachments\\[' + attachment_id + '\\]\\[description\\]]', fileSpan));
      progressSpan.progressbar();

      uploadBlob(file, {
          loadstartEventHandler: onLoadstart.bind(progressSpan),
          progressEventHandler: onProgress.bind(progressSpan)
        })
        .done(function(result) {
          progressSpan.progressbar( 'value', 100 ).remove();
          $('<input type="hidden" name="attachments[' + attachment_id + '][token]"/>').val(result.token).appendTo(fileSpan);
        })
        .fail(function(result) {
          progressSpan.text(result.statusText);
        }).always(function() {
          if(--addFile.uploading == 0) {
            $('input:submit', fileSpan.parents('form')).removeAttr('disabled');
          }
        });
    }

    return attachment_id;
  }
  return null;
}

addFile.nextAttachmentId = 1;
addFile.uploading = 0;

function removeFile(el) {
  $(el).parents('span').first().remove();
  fileFieldCount--;
}

function checkFileSize(file) {
  if (file.size && file.size > ATTACHMENT_CONFIG['MAX_FILE_SIZE']) {
    window.alert(ATTACHMENT_CONFIG['L_MAX_FILE_SIZE_EXCEEDED']);
    return false;
  }
  return true;
}

function uploadBlob(blob, options) {

  var actualOptions = $.extend({
    loadstartEventHandler: $.noop,
    progressEventHandler: $.noop
  }, options);

  var uploadUrl = ATTACHMENT_CONFIG['UPLOAD_PATH'];
  if (blob instanceof window.File) {
    uploadUrl += '?filename=' + encodeURIComponent(blob.name);
  }

  return $.ajax(uploadUrl, {
    type: 'POST',
    contentType: 'application/octet-stream',
    beforeSend: function(jqXhr) {
      jqXhr.setRequestHeader('Accept', 'application/json');
    },
    xhr: function() {
      var xhr = $.ajaxSettings.xhr();
      xhr.upload.onloadstart = actualOptions.loadstartEventHandler;
      xhr.upload.onprogress = actualOptions.progressEventHandler;
      return xhr;
    },
    data: blob,
    cache: false,
    processData: false
  });
}

function addInputFiles(inputEl) {

  var clearedFileInput = $(inputEl).clone();

  if (inputEl.files && inputEl.files.length > 1) {

    // multiple files selection input or dropped files, we have to handle them separately to allow user to remove them
    uploadAndAttachFiles(inputEl.files);
    $(inputEl).remove();
  } else {

    // classic upload on form submission upload
    var attachment_id;

    if (inputEl.files) {
      attachment_id = addFile(inputEl.files[0], false);
    } else {
      // "old browser" not supporting File API
      var aFilename = inputEl.value.split(/\/|\\/);
      attachment_id = addFile({ name: aFilename[ aFilename.length - 1 ] }, false);
    }

    if (attachment_id) {
      $(inputEl).attr({ name: 'attachments[' + attachment_id + '][file]', style: 'display:none;' }).appendTo('#attachments\\[' + attachment_id + '\\]');
    }
  }

  clearedFileInput.insertAfter('#attachments_fields');
}

function uploadAndAttachFiles(files) {
  $.each(files, function() {
    addFile(this, true);
  });
}

function handleFileDropEvent(e) {

  $(this).removeClass('fileover');
  blockEventPropagation(e);

  if ($.inArray('Files', e.dataTransfer.types) > -1) {

    uploadAndAttachFiles(e.dataTransfer.files);
  }
}

function dragOverHandler(e) {
  $(this).addClass('fileover');
  blockEventPropagation(e);
}

function dragOutHandler(e) {
  $(this).removeClass('fileover');
  blockEventPropagation(e);
}

function setupFileDrop() {
  if (window.File && window.FileList && window.ProgressEvent && window.FormData) {

    $.event.fixHooks.drop = { props: [ 'dataTransfer' ] };

    $('form div.box').has('input:file').each(function() {
      $(this).on({
          dragover: dragOverHandler,
          dragleave: dragOutHandler,
          drop: handleFileDropEvent
      });
    });
  }
}

$(document).ready(setupFileDrop);
