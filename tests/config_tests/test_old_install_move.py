import pytest
import os


@pytest.fixture(scope="module")
def install():
    pytest.helpers.clean_env()

    # Create old config
    pytest.helpers.old_install()

    pytest.helpers.run_command([pytest.INST_BIN, "/S", "/move-config"])
    yield
    pytest.helpers.clean_env()


def test_ssm_present_old_location(install):
    assert os.path.exists(f"{pytest.OLD_DIR}\\bin\\ssm.exe")


def test_binaries_present_old_location(install):
    assert os.path.exists(f"{pytest.OLD_DIR}\\bin\\python.exe")


def test_config_present_old_location(install):
    assert os.path.exists(f"{pytest.DATA_DIR}\\conf\\minion")


def test_config_correct(install):
    # The config file should be the old existing config in the new location, unchanged
    expected = pytest.OLD_CONTENT

    with open(f"{pytest.DATA_DIR}\\conf\\minion") as f:
        result = f.readlines()

    assert result == expected

