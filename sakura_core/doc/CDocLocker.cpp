#include "StdAfx.h"
#include "CDocLocker.h"
#include "CDocFile.h"
#include "window/CEditWnd.h"



// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//               �R���X�g���N�^�E�f�X�g���N�^                  //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

CDocLocker::CDocLocker()
: m_eIsDocWritable(UNTESTED)
, m_bNoMsg(false)
, m_bNeedRecheck(false)
{
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//                        ���[�h�O��                           //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

void CDocLocker::OnAfterLoad(const SLoadInfo& sLoadInfo)
{
	CEditDoc* pcDoc = GetListeningDoc();

	m_bNoMsg = sLoadInfo.bWritableNoMsg;

	// �t�@�C���̔r�����b�N
	pcDoc->m_cDocFileOperation.DoFileLock();
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//                        �Z�[�u�O��                           //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

void CDocLocker::OnBeforeSave(const SSaveInfo& sSaveInfo)
{
	CEditDoc* pcDoc = GetListeningDoc();

	// �t�@�C���̔r�����b�N����
	pcDoc->m_cDocFileOperation.DoFileUnlock();
}

void CDocLocker::OnAfterSave(const SSaveInfo& sSaveInfo)
{
	CEditDoc* pcDoc = GetListeningDoc();

	m_eIsDocWritable = WRITABLE;
	m_bNeedRecheck = false;

	// �t�@�C���̔r�����b�N
	pcDoc->m_cDocFileOperation.DoFileLock();
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//                         �`�F�b�N                            //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

//! �������߂邩����
void CDocLocker::_CheckWritable()
{
	CEditDoc* pcDoc = GetListeningDoc();

	m_bNeedRecheck = false;

	// �t�@�C�������݂��Ȃ��ꍇ (�u�J���v�ŐV�����t�@�C�����쐬��������) �́A�ȉ��̏����͍s��Ȃ�
	if( !fexist(pcDoc->m_cDocFile.GetFilePath()) ){
		m_eIsDocWritable = WRITABLE;
		return;
	}

	// �ǂݎ���p�t�@�C���̏ꍇ�́A�ȉ��̏����͍s��Ȃ�
	if( !pcDoc->m_cDocFile.HasWritablePermission() ){
		m_eIsDocWritable = UNWRITABLE;
		return;
	}

	WritableState IsWritableOld = m_eIsDocWritable;

	// �������߂邩����
	CDocFile& cDocFile = pcDoc->m_cDocFile;
	m_eIsDocWritable = cDocFile.IsFileWritable() ? WRITABLE : UNWRITABLE;
	if(m_eIsDocWritable == UNWRITABLE && ! m_bNoMsg && IsWritableOld != UNWRITABLE){
		// �r������Ă���ꍇ�������b�Z�[�W���o��
		// ���̑��̌����i�t�@�C���V�X�e���̃Z�L�����e�B�ݒ�Ȃǁj�ł͓ǂݎ���p�Ɠ��l�Ƀ��b�Z�[�W���o���Ȃ�
		// �ҏW�֎~�������t�@�C����ǂݒ������Ƃ��ɂ͉��߂ă��b�Z�[�W���o���Ȃ�(m_bNoMsg)�B
		// �������݉\��Ԃ� �s�ł͂Ȃ�(�s��,�\)���s�� �ƕω������ꍇ�ɂ������b�Z�[�W���o���B
		if( ::GetLastError() == ERROR_SHARING_VIOLATION ){
			TopWarningMessage(
				CEditWnd::getInstance()->GetHwnd(),
				LS( STR_ERR_DLGEDITDOC21 ),	//"%ts\n�͌��ݑ��̃v���Z�X�ɂ���ď����݂��֎~����Ă��܂��B"
				cDocFile.GetFilePathClass().IsValidPath() ? cDocFile.GetFilePath() : LS(STR_NO_TITLE1)	//"(����)"
			);
		}
	}
}
