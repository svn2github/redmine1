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

  if (fileFieldCount < 10) {

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
  clearedFileInput.val('');

  if (inputEl.files) {
    // upload files using ajax
    var sizeExceeded = false;
    $.each(inputEl.files, function() {
      if (this.size && this.size > ATTACHMENT_CONFIG['MAX_FILE_SIZE']) {sizeExceeded=true;}
    });
    if (sizeExceeded) {
      window.alert(ATTACHMENT_CONFIG['L_MAX_FILE_SIZE_EXCEEDED']);
    } else {
      $.each(inputEl.files, function() {addFile(this, true);});
    }
    $(inputEl).remove();
  } else {
    // browser not supporting the file API, upload on form submission
    var attachment_id;
    var aFilename = inputEl.value.split(/\/|\\/);
    attachment_id = addFile({ name: aFilename[ aFilename.length - 1 ] }, false);
    if (attachment_id) {
      $(inputEl).attr({ name: 'attachments[' + attachment_id + '][file]', style: 'display:none;' }).appendTo('#attachments\\[' + attachment_id + '\\]');
    }
  }

  clearedFileInput.insertAfter('#attachments_fields');
}
