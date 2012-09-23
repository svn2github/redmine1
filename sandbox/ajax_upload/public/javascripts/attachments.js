/* Redmine - project management software
   Copyright (C) 2006-2012  Jean-Philippe Lang */

var fileFieldCount = 0;

function addFile(inputEl, file, eagerUpload) {

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
      '<span id="attachments_' + attachment_id + '"> \
        <input type="text" class="filename readonly" name="attachments[' + attachment_id + '][filename]" readonly="readonly"></input> \
        <input type="text" class="description" name="attachments[' + attachment_id + '][description]" maxlength="255"></input> \
        <a href="#" onclick="removeFile(this); return false;" class="remove-upload">&nbsp</a> \
      </span>'
    );
    fileSpan.find('input.filename').val(file.name);
    fileSpan.find('input.description').attr('placeholder', $(inputEl).data('description-placeholder'))
    if (eagerUpload) {
      fileSpan.find('input.description, a').hide();
    }
    fileSpan.appendTo('#attachments_fields');

    if(eagerUpload) {
      var progressSpan = $('<div/>').insertAfter(fileSpan.find('input.filename'));
      progressSpan.progressbar();

      uploadBlob(file, $(inputEl).data('upload-path'), {
          loadstartEventHandler: onLoadstart.bind(progressSpan),
          progressEventHandler: onProgress.bind(progressSpan)
        })
        .done(function(result) {
          progressSpan.progressbar( 'value', 100 ).remove();
          $('<input type="hidden" name="attachments[' + attachment_id + '][token]"/>').val(result.token).appendTo(fileSpan);
          fileSpan.find('input.description, a').show();
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

function uploadBlob(blob, uploadUrl, options) {

  var actualOptions = $.extend({
    loadstartEventHandler: $.noop,
    progressEventHandler: $.noop
  }, options);

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
  var clearedFileInput = $(inputEl).clone().val('');
  var maxFileSize = $(inputEl).data('max-file-size');
  var maxFileSizeExceeded = $(inputEl).data('max-file-size-message');

  if (inputEl.files) {
    // upload files using ajax
    var sizeExceeded = false;
    $.each(inputEl.files, function() {
      if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;}
    });
    if (sizeExceeded) {
      window.alert(maxFileSizeExceeded);
    } else {
      $.each(inputEl.files, function() {addFile(inputEl, this, true);});
    }
    $(inputEl).remove();
  } else {
    // browser not supporting the file API, upload on form submission
    var attachment_id;
    var aFilename = inputEl.value.split(/\/|\\/);
    attachment_id = addFile(inputEl, { name: aFilename[ aFilename.length - 1 ] }, false);
    if (attachment_id) {
      $(inputEl).attr({ name: 'attachments[' + attachment_id + '][file]', style: 'display:none;' }).appendTo('#attachments\\[' + attachment_id + '\\]');
    }
  }

  clearedFileInput.insertAfter('#attachments_fields');
}
